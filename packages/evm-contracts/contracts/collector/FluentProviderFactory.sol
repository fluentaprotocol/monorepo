// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FluentProvider} from "./FluentProvider.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {FactoryProxy} from "../upgradeability/FactoryProxy.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFluentProvider} from "../interfaces/provider/IFluentProvider.sol";
import {IFluentProviderFactory} from "../interfaces/provider/IFluentProviderFactory.sol";

contract FluentProviderFactory is
    IFluentProviderFactory,
    FluentHostable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    IFluentProvider private _implementation;
    EnumerableSet.AddressSet private _providers;

    function initialize(
        IFluentHost host_,
        IFluentProvider implemenation_
    ) external initializer onlyProxy {
        _implementation = implemenation_;

        // host_.r

        __UUPSUpgradeable_init();
        __FluentHostable_init(host_);
    }

    function openProvider() external onlyProxy returns (address) {
        address account = _msgSender();

        // bytes memory initData = abi.encodeWithSignature(
        //     "initialize(address,address)",
        //     account,
        //     host
        // );

        FactoryProxy proxy = new FactoryProxy();
        address address_ = address(proxy);

        FluentProvider provider_ = FluentProvider(address_);

        proxy.initializeProxy(address(this));
        provider_.initialize(account, address(host));

        _providers.add(address_);

        return address_;
    }

    function closeProvider(IFluentProvider provider_) external onlyProxy {
        address account = _msgSender();

        if (provider_.owner() != account) {
            revert("UnauthorizedOwner");
        }

        // collector.terminate();

        _providers.remove(address(provider_));
    }

    function providerCount() external view returns (uint256) {
        return _providers.length();
    }

    function providerAt(uint256 index) external view returns (IFluentProvider) {
        return IFluentProvider(_providers.at(index));
    }

    function implementation() external view override returns (address) {
        return address(_implementation);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

}
