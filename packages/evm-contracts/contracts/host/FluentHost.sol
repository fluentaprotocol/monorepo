// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentProvider} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentTokenFactory} from "../interfaces/token/IFluentTokenFactory.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {Storage} from "../lib/Storage.sol";
import {Channel} from "../lib/Channel.sol";

import "hardhat/console.sol";

contract FluentHost is IFluentHost, UUPSUpgradeable, ContextUpgradeable {
    using Channel for bytes32;

    uint32 private baseFee;
    uint32 private minReward;
    uint32 private maxReward;

    uint64 private constant BUFFER_PERIOD = 48 * 60 * 60; // 2 DAYS
    uint32 private constant MAX_FEE = 8_000; // 8%
    uint32 private constant MAX_DISCOUNT = 3_000; // 3%

    IFluentTokenFactory tokenFactory;
    IFluentCollectorFactory collectorFactory;

    error UnauthorizedAccount(address account);

    error ChannelDoesNotExist(bytes32 channel);
    error ChannelAlreadyExists(bytes32 channel);

    mapping(bytes32 => bool) _channels;

    // mapping(bytes32 channel => address collector) private _channels;

    function initialize() external initializer {
        baseFee = 8_000;
        minReward = 1_000;
        maxReward = 2_000;

        __Context_init();
        __UUPSUpgradeable_init();
    }

    function channelData(
        bytes32 channel
    )
        external
        view
        returns (
            address provider,
            address account,
            uint64 expired,
            uint64 started,
            bytes4 bucket
        )
    {
        (provider, account, expired, started, bucket) = channel.data();
    }

    function openChannel(
        address provider,
        bytes4 bucket
    ) external returns (bytes32 channel) {
        address account = _msgSender();

        uint64 started = uint64(block.timestamp);
        uint64 expired = started + 60;

        IFluentToken token;
        uint256 value;

        channel = _channelId(provider, account);

        if (channel.exists()) {
            revert ChannelAlreadyExists(channel);
        }

        // token.transact(account, provider, value);
        channel.open(provider, account, expired, started, bucket);
    }

    function closeChannel(bytes32 channel) external {
        address sender = _msgSender();

        (
            address provider,
            address account,
            uint64 expired,
            uint64 started,
            bytes4 bucket
        ) = channel.data();

        if (provider == address(0)) {
            revert ChannelDoesNotExist(channel);
        }

        if (sender != account) {
            revert UnauthorizedAccount(sender);
        }


        IFluentToken token;

        token.transact(account, provider, 0);
        channel.close();
    }

    function processChannel(bytes32 channel, address processor) external {
        uint256 timestamp = block.timestamp;

        (
            address provider,
            address account,
            uint64 expired,
            uint64 started,
            bytes4 bucket
        ) = channel.data();

        IFluentToken token;
        uint256 total = 1e18;

        uint64 unlock = expired - BUFFER_PERIOD;

        if (timestamp < unlock) {
            revert("Stream Locked");
        }

        // value = subscribtion amount per interval

        // base fee = (tx.gasprice * gas consumption) * price of token / native (ex ETH/USDT);
        // reward fee = value * 2%
        // protocol fee = value * (base protocol fee - variable stream discount)%

        // Collector gets = value - (base fee + reward fee)

        // uint32 2;

        uint32 discount = MAX_DISCOUNT / 2;

        uint32 fee = baseFee - discount;
        uint32 reward = minReward + ((maxReward - minReward) / 2);

        token.transact(account, processor, reward);
        token.transact(account, address(this), reward);
        token.transact(account, provider, total - reward + fee);
    }

    function liquidateChannel(bytes32 stream) external {
        // check if liquidation is allowed
        // if yes, process token transaction
    }

    function _channelId(
        address provider,
        address account
    ) private pure returns (bytes32) {
        // return bytes32(0);
        return keccak256(abi.encode(provider, account));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyDAO {}

    modifier onlyDAO() {
        _;
    }
}
