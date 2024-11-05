// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";

import "hardhat/console.sol";

contract FluentHost is IFluentHost, UUPSUpgradeable, ContextUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    IFluentCollectorFactory public collectorFactory;

    // Collector variables
    // Bitmaps.BitMap private _streamStates;
    EnumerableSet.Bytes32Set private _streams; // get all collectors

    // Bitmaps.BitMap private _collectorIndicies;
    // EnumerableSet.AddressSet private _collectors; // get all collectors

    // mapping(bytes32 => address) private _collectorSlots;
    // Stream variables

    // mapping(address => uint256) private _collectorStates;

    //     EnumerableSet.AddressSet private _collectors;

    //     mapping(bytes32 => address) private _collectorSlots;
    // store in collector

    // -- stream data
    // timestamp
    // collector
    // sender
    // token
    // rate

    // -- store in factory
    // get a list of all the collectors,
    // open collector
    // close collector

    // -- store in host
    // check if a user is subscribed
    // get a list of all the streams owned by account
    // get a list of all the streams that exist

    // -- store in collector
    // store the info of the collector (name, description, etc..)
    // store the payment plans
    // allow as accesspoint to create steams
    //

    // modifier onlyCollector() {
    //     // if (!_factory.isCollector(_msgSender())) {
    //     //     revert("Only collector access allowed");
    //     // }

    //     _;
    // }

    // -- store the data of the subscription in host
    // get the sender of a stream with id \\  load from storage
    // get the collector of a stream with id \\  load from storage

    function initialize(IFluentCollectorFactory factory_) external initializer {
        collectorFactory = factory_;

        __Context_init();
        __UUPSUpgradeable_init();
    }

    /**************************************************************************
     * Modifiers
     *************************************************************************/
    modifier onlyCollector() {
        address sender = _msgSender();

        if (!collectorFactory.isCollector(sender)) {
            revert UnauthorizedCollector(sender);
        }

        _;
    }

    modifier onlyFactory() {
        address sender = _msgSender();

        if (address(collectorFactory) != sender) {
            revert UnauthorizedFactory(sender);
        }

        _;
    }

    /**************************************************************************
     * Stream functions
     *************************************************************************/
    function openStream(
        address account,
        IFluentToken token
    ) external onlyCollector onlyProxy returns (bytes32) {
        address collector = _msgSender();

        // generate stream id based on token

        revert("FluentHost.openStream() not implemented");
    }

    function closeStream(address account) external view onlyCollector onlyProxy {
        address collector = _msgSender();

        revert("FluentHost.closeStream() not implemented");
    }

    // collector

    // factory
    // function _openCollector() private {
    //     address _s = _msgSender();
    // }

    // function _closeCollector() private {
    //     address _s = _msgSender();
    // }

    // streams
    // function openStream(
    //     address account
    // ) external onlyCollector returns (bytes32) {
    //     // (bool available, uint index) = _streamIndicies.nextUnset(account);
    //     // if (!available) {
    //     //     revert("No available stream slot for account");
    //     // }
    //     // address collector = _msgSender();
    //     // bytes32 stream = keccak256(abi.encode(account, index));
    // }

    // function closeStream(bytes32 stream) external onlyCollector {
    //     address collector = _msgSender();
    // }

    // function streamInfo(bytes32 stream) external pure {
    //     // sender
    //     // collector
    //     // all other info
    // }

    // function _streamCollector(bytes32 stream) private {
    //     // load the data from the storage
    // }

    // function _streamId(
    //     address account,
    //     uint index
    // ) private pure returns (bytes32) {
    //     return keccak256(abi.encode(account, index));
    // }

    // stream id is generated by account id and index
    // stream id is also the storage slot inside the collector
    // stream id is stored in the host contract.

    // function _openStream(
    //     address sender,
    //     IFluentCollector collector
    // ) private returns (bytes32) {
    //     bytes32 stream = _streamId(sender, address(collector));

    //     //  Check if the stream already exists or not
    //     if (_streams.contains(stream)) {
    //         revert("stream already exists");
    //     }

    //     // Check if the collector is active and available
    //     if (!collector.isActive()) {
    //         revert("Collector is not active");
    //     }

    //     _streams.add(stream);

    //     return stream;
    // }

    // function _closeStream(address sender, IFluentCollector collector) private {
    //     bytes32 stream = _streamId(sender, address(collector));

    //     // Check if the stream exists
    //     if (!_streams.contains(stream)) {
    //         revert("stream already exists");
    //     }

    //     // Remove the stream from the registry
    //     _streams.remove(stream);
    // }

    // function _streamId(
    //     address sender,
    //     address recipient
    // ) private pure returns (bytes32) {
    //     return keccak256(abi.encode("fluenta.stream", sender, recipient));
    // }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    // function _authorizeUpgrade(address newImplementation) internal override {}

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

    function openStream(address account) external override returns (bytes32) {}
}
