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
    error ProviderBucketsInvalid();
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

    /** Provider Methods */
    function openProvider(
        string calldata name,
        Bucket[] calldata buckets,
        Endpoint[] calldata endpoints
    ) external returns (bytes32) {
        address account = _msgSender();

        // Ensure there is at least one bucket
        if (buckets.length == 0) {
            revert ProviderBucketsInvalid();
        }

        // Ensure the name is always between 1 and 32 characters long
        if (bytes(name).length > 32 || bytes(name).length == 0) {
            revert ProviderNameInvalid();
        }

        // Load the storage pointer from the provider mapping
        bytes32 provider = ProviderUtils.id(name, account);
        Provider storage provider_ = _providers[provider];

        // Ensure the provider does not already exist
        if (provider_.exists()) {
            revert ProviderAlreadyExists();
        }

        // Insert all the buckets
        BucketCollection storage buckets_ = _buckets[provider];
        for (uint i; i < buckets.length; i++) {
            if (!buckets_.add(buckets[i].tag(), buckets[i])) {
                revert EndpointAlreadyExists();
            }
        }

        // Insert all the endpoints
        EndpointCollection storage endpoints_ = _endpoints[provider];
        for (uint i; i < endpoints.length; i++) {
            Endpoint calldata endpoint = endpoints[i];

            // Ensure the bucket exists
            if (!buckets_.contains(endpoint.bucket)) {
                revert BucketDoesNotExist();
            }

            // Insert the endpoint, returns false if the endpoint already exists
            if (!endpoints_.add(endpoint.tag(), endpoint)) {
                revert EndpointAlreadyExists();
            }
        }

        // Set the actual provider information
        provider_.open(account, name);

        return provider;
    }

    function closeProvider(bytes32 provider) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        // Ensure only the owner has access
        if (account != provider_.owner) {
            revert ProviderUnauthorizedAccount(account);
        }

        // Delete all endpoint and bucket data
        delete _buckets[provider];
        delete _endpoints[provider];

        //  Delete provider information
        provider_.close();
    }

    function transferProvider(bytes32 provider, address account) external {
        // Ensure we cannot assign invalid owner addresses
        if (account == address(0)) {
            revert ProviderInvalidAccount(account);
        }

        address sender = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        // Ensure only the owner has access
        if (sender != provider_.owner) {
            revert ProviderUnauthorizedAccount(sender);
        }

        // We cannot transfer ownership to ourselves
        if (account == provider_.owner) {
            revert ProviderInvalidAccount(account);
        }

        // Set the owner adderss
        provider_.owner = account;
    }

    /** Bucket Methods */
    function createBucket(bytes32 provider, Bucket calldata data) external {
        address account = _msgSender();

        Provider storage provider_ = _getProvider(provider);
        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        BucketCollection storage buckets_ = _buckets[provider];
        if (!buckets_.add(data.tag(), data)) {
            revert BucketAlreadyExists();
        }
    }

    function removeBucket(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();
        Provider storage provider_ = _getProvider(provider);

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        BucketCollection storage buckets_ = _buckets[provider];
        bool exists = buckets_.remove(tag);

        if (!exists) {
            revert BucketDoesNotExist();
        }
    }

    function renameBucket(
        bytes32 provider,
        bytes4 bucket,
        string calldata name
    ) external {
        address account = _msgSender();

        if (_getProvider(provider).owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        _getBucket(provider, bucket).name = name;
    }

    /** Endpoint Methods */
    function createEndpoint(bytes32 provider, Endpoint calldata data) external {
        address account = _msgSender();

        if (_getProvider(provider).owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        EndpointCollection storage endpoints_ = _endpoints[provider];
        bool success = endpoints_.add(data.tag(), data);

        if (!success) {
            revert EndpointAlreadyExists();
        }
    }

    function removeEndpoint(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();

        if (_getProvider(provider).owner != account) {
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
        if (_getProvider(provider).owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        Endpoint storage endpoint_ = _getEndpoint(provider, endpoint);

        endpoint_.amount = amount;
    }

    /** View Methods */
    function getTransaction(
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

        Interval interval_ = _getBucket(provider, endpoint_.bucket).interval;

        return (endpoint_.amount, endpoint_.token, provider_.owner, interval_);
    }

    function getProvider(
        bytes32 provider
    ) external view returns (string memory name, address owner) {
        Provider storage provider_ = _getProvider(provider);

        name = provider_.name;
        owner = provider_.owner;
    }

    function getProviderEndpoints(
        bytes32 id
    ) external view returns (bytes4[] memory) {
        return _endpoints[id].tags;
    }

    function getProviderBuckets(
        bytes32 id
    ) external view returns (bytes4[] memory) {
        return _buckets[id].tags;
    }

    /** Utility Methods */
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
