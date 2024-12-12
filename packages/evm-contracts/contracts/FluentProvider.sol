// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {String} from "./libraries/String.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {Bucket, BucketUtils} from "./libraries/Bucket.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Provider, ProviderUtils} from "./libraries/Provider.sol";

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

    error ProviderUnauthorizedAccount(address account);
    error ProviderInvalidAccount(address account);

    error ProviderAlreadyExists();
    error ProviderDoesNotExist();
    error ProviderBucketsInvalid();
    error ProviderNameInvalid();
    error BucketDoesNotExist();

    event BucketCreated();

    mapping(bytes32 id => mapping(bytes4 => Bucket)) private _buckets;
    mapping(bytes32 id => Provider) private _providers;

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

        emit BucketCreated();

        return id;
    }

    function closeProvider(bytes32 id) external {
        address account = _msgSender();
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        if (account != provider.owner) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider.close();
    }

    function transferProvider(bytes32 id, address account) external {
        if (account == address(0)) {
            revert ProviderInvalidAccount(account);
        }

        address sender = _msgSender();
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        if (sender != provider.owner) {
            revert ProviderUnauthorizedAccount(sender);
        }

        if (account == provider.owner) {
            revert ProviderInvalidAccount(account);
        }

        provider.owner = account;
    }

    function getProvider(
        bytes32 id
    ) external view returns (string memory name, address owner) {
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        name = provider.name;
        owner = provider.owner;
    }

    function createBucket(bytes32 id, Bucket calldata data) external {
        address account = _msgSender();
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        // provider.addBucket();
    }

    function removeBucket(bytes32 id, bytes4 bucket) external {
        address account = _msgSender();
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider.removeBucket(bucket);
    }

    function modifyBucket(bytes32 id, bytes4 bucket) external {
        address account = _msgSender();
        Provider storage provider = _providers[id];

        if (!provider.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider.modifyBucket(bucket);
    }

    function test(
        bytes32 provider,
        bytes4 bucket
    ) external view returns (Bucket memory, address recipient) {
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        Bucket storage bucket_ = _buckets[provider][bucket];

        if (!bucket_.exists()) {
            revert BucketDoesNotExist();
        }

        return (bucket_, provider_.owner);
    }

    function getBucket(
        bytes32 provider,
        bytes4 bucket
    ) external view override returns (Bucket memory) {
        // Bucket storage $ = _buckets[provider][bucket];
        // if (!$.exists()) {
        //     revert("BucketDoesNotExist");
        // }
        // return $;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
