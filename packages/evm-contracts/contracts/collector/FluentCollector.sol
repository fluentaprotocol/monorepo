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
import {Storage} from "../lib/Storage.sol";

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "hardhat/console.sol";

contract FluentCollector is
    IFluentCollector,
    FluentHostable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IFluentToken;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Storage for bytes32;

    address public owner;
    address public factory;

    mapping(bytes32 => address) _streams;

    function initialize(
        address owner_,
        address factory_,
        IFluentHost host_
    ) external initializer {
        owner = owner_;
        factory = factory_;

        __Context_init();
        __UUPSUpgradeable_init();
        __FluentHostable_init(host_);
    }

    function openStream(IFluentToken token) external {
        address account = _msgSender();

        // Check if account is not the owner of this collector
        if (account == owner) {
            revert("InvalidSender");
        }

        bytes32 id = _streamId(account);

        // Check if stream not already exists
        if (_streams[id] != address(0)) {
            revert("StreamAlreadyExists");
        }

        // Calculate the first subscription amount + deposit
        // uint256 amount = 1e18;
        // uint256 deposit = (amount / 100) * 33;

        // Transfer the first subscription amount + deposit
        // token.safeTransferFrom(account, address(this), amount + deposit);

        // Register the stream with the host
        host.registerStream(id, token);

        // Store the stream data
        bytes32[] memory data = new bytes32[](1);
        data[0] = bytes32(uint256(uint160(account)));

        id.store(data);

        _streams[id] = account;
    }

    function closeStream() external {
        address account = _msgSender();
        bytes32 stream = _streamId(account);

        // Load the stream data
        bytes32[] memory data = stream.load(1);

        // // Unpack the stream data
        // uint256 amount = uint256(data[0]);
        IFluentToken token = IFluentToken(address(0));

        // uint256 reward = (amount * 2e6) / 100e6; // 2% fee
        // uint256 due = amount - reward;

        host.deleteStream(stream, token);

        stream.clear(1);
        // TODO update all the data here

        delete _streams[stream];
    }

    function terminate() external view onlyFactory {
        // TODO: transfer all of the balances to the owner account

        revert("terminate() not implemented yet");
    }

    function _streamId(address account) private view returns (bytes32) {
        return keccak256(abi.encode(account, address(this)));
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

    modifier onlyFactory() {
        address sender = _msgSender();

        if (sender != factory) {
            revert("UnauthorizedFactory");
        }

        _;
    }
}
