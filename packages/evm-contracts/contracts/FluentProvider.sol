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

contract FluentProvider is ContextUpgradeable, UUPSUpgradeable {
    using String for *;

    using BucketUtils for Bucket;
    using ProviderUtils for Provider;

    error ProviderUnauthorizedAccount(address account);
    error ProviderInvalidAccount(address account);

    error ProviderAlreadyInitialized();
    error ProviderNotInitialized();
    error ProviderBucketsInvalid();
    error ProviderNameInvalid();

    mapping(bytes32 id => Provider) private _providers;

    function initialize() external initializer {
        __Context_init();
        __UUPSUpgradeable_init();
    }

    function openProvider(
        string calldata name,
        Bucket[] calldata buckets
    ) external {
        address account = _msgSender();

        // Validate inputs
        if (buckets.length == 0) {
            revert ProviderBucketsInvalid();
        }

        if (bytes(name).length > 32 || bytes(name).length == 0) {
            revert ProviderNameInvalid();
        }

        bytes32 identifier = ProviderUtils.identifier(name, account);
        Provider storage $ = _providers[identifier];

        if ($.isActive()) {
            revert ProviderAlreadyInitialized();
        }

        $.open(account, name, buckets);
    }

    function closeProvider(bytes32 identifier) external {
        address account = _msgSender();
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        if (account != $.owner) {
            revert ProviderUnauthorizedAccount(account);
        }

        $.close();
    }

    function transferProvider(bytes32 identifier, address account) external {
        if (account == address(0)) {
            revert ProviderInvalidAccount(account);
        }

        address sender = _msgSender();
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        if (sender != $.owner) {
            revert ProviderUnauthorizedAccount(sender);
        }

        if (account == $.owner) {
            revert ProviderInvalidAccount(account);
        }

        $.owner = account;
    }

    function provider(
        bytes32 identifier
    ) external view returns (string memory name, address owner) {
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        name = $.name;
        owner = $.owner;
    }

    function createBucket(
        bytes32 identifier,
        uint64 /**interval*/,
        address /**token*/,
        uint256 /**amount*/
    ) external {
        address account = _msgSender();
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        if ($.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        $.addBucket();
    }

    function removeBucket(bytes32 identifier, bytes4 bucket) external {
        address account = _msgSender();
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        if ($.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        $.removeBucket(bucket);
    }

    function modifyBucket(bytes32 identifier, bytes4 bucket) external {
        address account = _msgSender();
        Provider storage $ = _providers[identifier];

        if (!$.isActive()) {
            revert ProviderNotInitialized();
        }

        if ($.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        $.modifyBucket(bucket);
    }
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
