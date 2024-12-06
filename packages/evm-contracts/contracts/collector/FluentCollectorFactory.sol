// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FluentProvider} from "./FluentProvider.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentProvider} from "../interfaces/collector/IFluentCollector.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FluentCollectorFactory is
    IFluentCollectorFactory,
    FluentHostable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    IFluentProvider public implementation;
    EnumerableSet.AddressSet private _collectors;

    function initialize(
        IFluentHost host,
        IFluentProvider implemenation_
    ) external initializer onlyProxy {
        implementation = implemenation_;

        __UUPSUpgradeable_init();
        __FluentHostable_init(host);
    }

    function openCollector() external onlyProxy {
        address account = _msgSender();

        UUPSProxy proxy = new UUPSProxy();

        address address_ = address(proxy);
        FluentProvider collector = FluentProvider(address_);

        proxy.initializeProxy(address(implementation));
        collector.initialize(account, host);

        _collectors.add(address_);
    }

    function closeCollector(IFluentProvider collector) external onlyProxy {
        address account = _msgSender();

        if (collector.owner() != account) {
            revert("UnauthorizedOwner");
        }

        // collector.terminate();

        _collectors.remove(address(collector));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
