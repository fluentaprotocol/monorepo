// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FluentCollector} from "./FluentCollector.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FluentCollectorFactory is
    IFluentCollectorFactory,
    FluentHostable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    IFluentCollector public implementation;
    EnumerableSet.AddressSet private _collectors;

    function initialize(
        IFluentHost host,
        IFluentCollector implemenation_
    ) external initializer onlyProxy {
        implementation = implemenation_;

        __UUPSUpgradeable_init();
        __FluentHostable_init(host);
    }

    function openCollector() external onlyProxy {
        address account = _msgSender();

        UUPSProxy proxy = new UUPSProxy();

        address address_ = address(proxy);
        FluentCollector collector = FluentCollector(address_);

        proxy.initializeProxy(address(implementation));
        collector.initialize(account, address(this), host);

        _collectors.add(address_);
    }

    function closeCollector(IFluentCollector collector) external onlyProxy {
        address account = _msgSender();

        if (collector.owner() != account) {
            revert("UnauthorizedOwner");
        }

        collector.terminate();

        _collectors.remove(address(collector));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
