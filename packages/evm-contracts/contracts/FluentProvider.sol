// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {String} from "./libraries/String.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {Bucket, BucketUtils} from "./libraries/Bucket.sol";
import {Interval} from "./libraries/Interval.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Provider, ProviderUtils} from "./libraries/Provider.sol";
import {BucketCollection, CollectionUtils} from "./libraries/Collection.sol";

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
    using ProviderUtils for Provider;
    using CollectionUtils for BucketCollection;

    error ProviderUnauthorizedAccount(address account);
    error ProviderInvalidAccount(address account);

    error ProviderAlreadyExists();
    error ProviderDoesNotExist();
    error ProviderBucketsInvalid();
    error ProviderNameInvalid();
    // error BucketDoesNotExist();

    mapping(bytes32 => Provider) private _providers;

    function initialize() external initializer {
        __Context_init();
        __UUPSUpgradeable_init();
    }

    function openProvider(
        string calldata name,
        Bucket[] calldata buckets
    ) external returns (bytes32) {
        address account = _msgSender();

        // Validate inputs
        if (buckets.length == 0) {
            revert ProviderBucketsInvalid();
        }

        if (bytes(name).length > 32 || bytes(name).length == 0) {
            revert ProviderNameInvalid();
        }

        bytes32 id = ProviderUtils.id(name, account);
        Provider storage provider = _providers[id];

        if (provider.exists()) {
            revert ProviderAlreadyExists();
        }

        provider.open(account, name, buckets);

        return id;
    }

    function closeProvider(bytes32 provider) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

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
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

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

    // function getProviderBuckets(
    //     bytes32 id
    // ) external view returns (bytes4[] memory) {
    //     return _providers[id].buckets.tags;
    // }

    function createBucket(bytes32 provider, Bucket calldata data) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.addBucket(data);
    }

    function removeBucket(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.removeBucket(tag);
    }

    function modifyBucket(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.modifyBucket(tag);
    }

    function getBucket(
        bytes32 provider,
        bytes4 tag
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
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }


        Bucket storage bucket_ = provider_.getBucket(tag);

        return (
            bucket_.amount,
            bucket_.token,
            provider_.owner,
            bucket_.interval
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
