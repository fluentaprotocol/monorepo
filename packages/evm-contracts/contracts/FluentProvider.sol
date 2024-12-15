// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {String} from "./libraries/String.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {Bucket, BucketUtils, BucketCollection} from "./libraries/Bucket.sol";
import {Endpoint, EndpointUtils, EndpointCollection} from "./libraries/Endpoint.sol";
import {Interval} from "./libraries/Interval.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Provider, ProviderUtils} from "./libraries/Provider.sol";
import {CollectionUtils} from "./libraries/Collection.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

contract FluentProvider is
    IFluentProvider,
    ContextUpgradeable,
    UUPSUpgradeable
{
    using String for *;

    using BucketUtils for Bucket;
    using BucketUtils for BucketCollection;
    using EndpointUtils for Endpoint;
    using EndpointUtils for EndpointCollection;
    using ProviderUtils for Provider;

    error ProviderUnauthorizedAccount(address account);
    error ProviderInvalidAccount(address account);

    error ProviderAlreadyExists();
    error ProviderDoesNotExist();
    error ProviderParamsInvalid();
    error ProviderNameInvalid();

    error EndpointAlreadyExists();
    error EndpointDoesNotExist();

    error BucketAlreadyExists();
    error BucketDoesNotExist();

    mapping(bytes32 => Provider) private _providers;
    mapping(bytes32 => BucketCollection) private _buckets;
    mapping(bytes32 => EndpointCollection) private _endpoints;

    function initialize() external initializer {
        __Context_init();
        __UUPSUpgradeable_init();
    }

    function openProvider(
        string calldata name,
        Bucket[] calldata buckets,
        Endpoint[] calldata endpoints
    ) external returns (bytes32) {
        address account = _msgSender();

        // Validate inputs
        if (buckets.length == 0) {
            revert ProviderParamsInvalid();
        }

        if (bytes(name).length > 32 || bytes(name).length == 0) {
            revert ProviderNameInvalid();
        }

        bytes32 provider = ProviderUtils.id(name, account);
        Provider storage provider_ = _providers[provider];

        if (provider_.exists()) {
            revert ProviderAlreadyExists();
        }

        BucketCollection storage buckets_ = _buckets[provider];

        // Cache length for efficiency and iterate buckets
        uint bucketLength = buckets.length;
        for (uint i; i < bucketLength; ) {
            Bucket calldata bucket = buckets[i];
            bool success = buckets_.add(bucket.tag(), bucket);

            if (!success) {
                revert EndpointAlreadyExists();
            }

            unchecked {
                ++i;
            }
        }

        EndpointCollection storage endpoints_ = _endpoints[provider];

        // Cache length for efficiency and iterate buckets
        uint endpointsLen = endpoints.length;
        for (uint i; i < endpointsLen; ) {
            Endpoint calldata endpoint = endpoints[i];

            if (endpoint.bucket != bytes4(0)) {
                // TODO check if endpoint bucket exists
            }

            bool success = endpoints_.add(endpoint.tag(), endpoint);

            if (!success) {
                revert EndpointAlreadyExists();
            }

            unchecked {
                ++i;
            }
        }

        provider_.open(account, name);

        return provider;
    }

    function closeProvider(bytes32 provider) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (account != provider_.owner) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.close();
    }

    function transferProvider(bytes32 provider, address account) external {
        if (account == address(0)) {
            revert ProviderInvalidAccount(account);
        }

        address sender = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (sender != provider_.owner) {
            revert ProviderUnauthorizedAccount(sender);
        }

        if (account == provider_.owner) {
            revert ProviderInvalidAccount(account);
        }

        provider_.owner = account;
    }

    function getProvider(
        bytes32 provider
    ) external view returns (string memory name, address owner) {
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        name = provider_.name;
        owner = provider_.owner;
    }

    function getProviderEndpoints(
        bytes32 id
    ) external view returns (bytes4[] memory) {
        return _endpoints[id].tags;
    }

    function createEndpoint(bytes32 provider, Endpoint calldata data) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        EndpointCollection storage endpoints_ = _endpoints[provider];
        bytes4 tag = data.tag();

        bool success = endpoints_.add(tag, data);

        if (!success) {
            revert EndpointAlreadyExists();
        }
    }

    function removeEndpoint(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        EndpointCollection storage endpoints_ = _endpoints[provider];

        bool exists = endpoints_.remove(tag);

        if (!exists) {
            revert EndpointDoesNotExist();
        }
    }

    function modifyEndpoint(
        bytes32 provider,
        bytes4 endpoint,
        uint256 amount
    ) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        Endpoint storage endpoint_ = _getEndpoint(provider, endpoint);

        endpoint_.amount = amount;
    }

    function getEndpoint(
        bytes32 provider,
        bytes4 endpoint
    )
        external
        view
        returns (
            uint256 value,
            address token,
            address recipient,
            Interval interval
        )
    {
        Provider storage provider_ = _getProvider(provider);
        Endpoint storage endpoint_ = _getEndpoint(provider, endpoint);
        Bucket storage bucket_ = _getBucket(provider, endpoint_.bucket);

        return (
            endpoint_.amount,
            endpoint_.token,
            provider_.owner,
            bucket_.interval
        );
    }

    function _getBucket(
        bytes32 provider,
        bytes4 bucket
    ) private view returns (Bucket storage) {
        BucketCollection storage buckets_ = _buckets[provider];

        if (!buckets_.contains(bucket)) {
            revert BucketDoesNotExist();
        }

        return buckets_.get(bucket);
    }

    function _getEndpoint(
        bytes32 provider,
        bytes4 endpoint
    ) private view returns (Endpoint storage) {
        EndpointCollection storage endpoints_ = _endpoints[provider];

        if (!endpoints_.contains(endpoint)) {
            revert EndpointDoesNotExist();
        }

        return endpoints_.get(endpoint);
    }

    function _getProvider(
        bytes32 provider
    ) private view returns (Provider storage) {
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        return provider_;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
