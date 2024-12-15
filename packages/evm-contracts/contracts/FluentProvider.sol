// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {String} from "./libraries/String.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {Endpoint, BucketParams, EndpointUtils} from "./libraries/Bucket.sol";
import {Interval} from "./libraries/Interval.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Provider, ProviderUtils} from "./libraries/Provider.sol";
import {EndpointCollection, CollectionUtils} from "./libraries/Collection.sol";

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

    using EndpointUtils for Endpoint;
    using ProviderUtils for Provider;
    using CollectionUtils for EndpointCollection;

    error ProviderUnauthorizedAccount(address account);
    error ProviderInvalidAccount(address account);

    error ProviderAlreadyExists();
    error ProviderDoesNotExist();
    error ProviderEndpointsInvalid();
    error ProviderNameInvalid();

    mapping(bytes32 => Provider) private _providers;

    function initialize() external initializer {
        __Context_init();
        __UUPSUpgradeable_init();
    }

    function openProvider(
        string calldata name,
        Endpoint[] calldata endpoints
    ) external returns (bytes32) {
        address account = _msgSender();

        // Validate inputs
        if (endpoints.length == 0) {
            revert ProviderEndpointsInvalid();
        }

        if (bytes(name).length > 32 || bytes(name).length == 0) {
            revert ProviderNameInvalid();
        }

        bytes32 id = ProviderUtils.id(name, account);
        Provider storage provider = _providers[id];

        if (provider.exists()) {
            revert ProviderAlreadyExists();
        }

        provider.open(account, name, endpoints);

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

    // function getProviderEndpoints(
    //     bytes32 id
    // ) external view returns (bytes4[] memory) {
    //     return _providers[id].buckets.tags;
    // }

    function createEndpoint(bytes32 provider, Endpoint calldata data) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.addEndpoint(data);
    }

    function removeEndpoint(bytes32 provider, bytes4 tag) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.removeEndpoint(tag);
    }

    function modifyEndpoint(bytes32 provider, bytes4 tag, uint256 amount) external {
        address account = _msgSender();
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }

        if (provider_.owner != account) {
            revert ProviderUnauthorizedAccount(account);
        }

        provider_.modifyEndpoint(tag, amount);
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
        Provider storage provider_ = _providers[provider];

        if (!provider_.exists()) {
            revert ProviderDoesNotExist();
        }


        Endpoint storage endpoint_ = provider_.getEndpoint(endpoint);

        return (
            endpoint_.amount,
            endpoint_.token,
            provider_.owner,
            endpoint_.interval
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
