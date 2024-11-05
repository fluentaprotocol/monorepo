// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {FluentHostable} from "../host/FluentHostable.sol";

import "hardhat/console.sol";

contract FluentCollector is IFluentCollector, UUPSUpgradeable, FluentHostable {
    bytes32 public slot;

    mapping(address => bytes32) private _streams;

    /// @dev initialize the proxy contract
    function initialize(IFluentHost host_, bytes32 slot_) external initializer {
        slot = slot_;

        __Context_init();
        __UUPSUpgradeable_init();
        __FluentHostable_init(host_);
    }

    /**************************************************************************
     * Modifiers
     *************************************************************************/
    /// @dev only allow factory to be msg sender
    modifier onlyFactory() {
        address sender = _msgSender();

        if (sender != address(host.collectorFactory())) {
            revert UnauthorizedFactory(sender);
        }

        _;
    }

    /**************************************************************************
     * Metadata functions
     *************************************************************************/
    /// @dev The collector factory that created this collector
    function factory() external view returns (IFluentCollectorFactory) {
        return host.collectorFactory();
    }

    /**************************************************************************
     * Stream functions
     *************************************************************************/
    /// @dev open a new stream with the collector
    function openStream(IFluentToken token) external onlyProxy {
        address account = _msgSender();

        if (_streams[account] != bytes32(0)) {
            revert("User already subscribed");
        }

        _streams[account] = host.openStream(account, token);
    }

    /// @dev close the exisiting stream with the collector if the accoutn has one
    function closeStream() external {
        address account = _msgSender();
        bytes32 stream = _streams[account];

        if (stream == bytes32(0)) {
            revert("User not subscribed");
        }

        host.closeStream(stream);

        delete _streams[account];
    }

    /// @dev terminate collector and mark as destroyed
    function terminate() external view onlyFactory onlyProxy {
        revert("FluentCollector.terminate() not implemented");
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(address newImplementation) internal override {}
}
