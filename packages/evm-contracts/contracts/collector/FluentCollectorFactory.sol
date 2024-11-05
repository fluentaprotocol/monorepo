// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Bitmap, BitmapUtils} from "../lib/Bitmap.sol";
import {Account} from "../lib/Account.sol";
import {Storage} from "../lib/Storage.sol";

import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FluentCollectorFactory is
    IFluentCollectorFactory,
    FluentHostable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Storage for bytes32;
    using Account for address;
    using BitmapUtils for Bitmap;

    IFluentCollector public implementation;

    EnumerableSet.AddressSet private _collectors;

    mapping(bytes32 slot => address collector) private _slots;
    mapping(address account => Bitmap) private _accounts;

    function initialize(
        IFluentHost host,
        IFluentCollector implemenation_
    ) external initializer onlyProxy {
        implementation = implemenation_;

        __UUPSUpgradeable_init();
        __FluentHostable_init(host);
    }

    /**************************************************************************
     * Core functions
     *************************************************************************/
    function isCollector(
        address collector
    ) external view onlyProxy returns (bool) {
        return _collectors.contains(collector);
    }

    function openCollector() external onlyProxy {
        address account = _msgSender();

        (bool available, uint index) = _accounts[account].nextUnset();

        if (!available) {
            revert("User max collectors reached");
        }

        UUPSProxy proxy = new UUPSProxy();
        address proxyAddress = address(proxy);

        proxy.initializeProxy(address(implementation));

        bytes32 slot = account.slot(index);
        IFluentCollector collector = IFluentCollector(proxyAddress);

        collector.initialize(host, slot);

        _collectors.add(proxyAddress);
        _accounts[account].set(index);

        _slots[slot] = proxyAddress;
    }

    function closeCollector(IFluentCollector collector) external onlyProxy {
        address account = _msgSender();
        bytes32 slot = collector.slot();
        uint256 index = account.slotIndex(slot);

        collector.terminate();

        _collectors.remove(address(collector));
        _accounts[account].unset(index);

        delete _slots[slot];
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
