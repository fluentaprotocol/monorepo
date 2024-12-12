// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IFluentDao} from "./interfaces/IFluentDao.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Channel, ChannelUtils} from "./libraries/Channel.sol";
import {Bucket, BucketUtils} from "./libraries/Bucket.sol";
import {DateTime} from "./libraries/DateTime.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {IFluentProviderFactory} from "../interfaces/provider/IFluentProviderFactory.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {IFluentTokenFactory} from "./interfaces/IFluentTokenFactory.sol";
import {IFluentHost} from "./interfaces/IFluentHost.sol";
// import {Storage} from "./lib/Storage.sol";
// import {Channel} from "./lib/Channel.sol";

import "hardhat/console.sol";

contract FluentHost is IFluentHost, UUPSUpgradeable, ContextUpgradeable {
    using ChannelUtils for Channel;
    using BucketUtils for Bucket;

    // uint32 private baseFee;
    // uint32 private minReward;
    // uint32 private maxReward;

    uint64 private constant PROCESS_PERIOD = 48 * 60 * 60; // 2 DAYS
    uint32 private constant MAX_FEE = 8_000; // 8%
    // uint32 private constant MAX_DISCOUNT = 3_000; // 3%

    IFluentDao public dao;
    IFluentProvider public provider;
    // IFluentTokenFactory tokenFactory;
    // IFluentProviderFactory private _providerFactory;

    error ChannelUnauthorized(address account);
    error ChannelDoesNotExist(bytes32 channel);
    error ChannelAlreadyExists(bytes32 channel);

    mapping(bytes32 => Channel) _channels;

    function initialize(
        IFluentDao dao_,
        IFluentProvider provider_
    ) external initializer {
        dao = dao_;
        provider = provider_;

        __Context_init();
        __UUPSUpgradeable_init();
    }

    function getChannel(bytes32 id) external view returns (Channel memory) {
        Channel storage channel = _channels[id];

        if (!channel.initialized()) {
            revert ChannelDoesNotExist(id);
        }

        return channel;
    }

    function openChannel(
        bytes32 provider_,
        bytes4 bucket_
    ) external returns (bytes32) {
        address account = _msgSender();
        bytes32 id = keccak256(abi.encode(provider_, account));

        Channel storage channel = _channels[id];

        if (channel.initialized()) {
            revert ChannelAlreadyExists(id);
        }

        (Bucket memory bucket, address recipient) = provider.test(
            provider_,
            bucket_
        );

        uint64 expired = uint64(DateTime.addMonths(block.timestamp, 1));

        IFluentToken(bucket.token).transact(account, recipient, 0);
        channel.open(provider_, account, expired, bucket_);

        return id;
    }

    function closeChannel(bytes32 id) external {
        address account = _msgSender();
        Channel storage channel = _channels[id];

        if (!channel.initialized()) {
            revert ChannelDoesNotExist(id);
        }

        if (channel.account != account) {
            revert ChannelUnauthorized(account);
        }

        channel.close();
    }

    function processChannel(bytes32 id) external {
        address sender = _msgSender();
        Channel storage channel = _channels[id];

        if (!channel.initialized()) {
            revert ChannelDoesNotExist(id);
        }

        uint64 timestamp = uint64(block.timestamp);
        uint64 unlock = channel.expired - PROCESS_PERIOD;

        if (timestamp < unlock) {
            revert("ChannelLocked");
        }

        (Bucket memory bucket, address recipient) = provider.test(
            id,
            channel.bucket
        );

        // TODO THIS DOES NOT WORK

        uint256 progress = ((timestamp - unlock) * 100_000) / PROCESS_PERIOD;
        uint256 reward = (((bucket.amount * MAX_FEE) / 100_000) * progress) /
            100_000;

        IFluentToken(bucket.token).transact(
            sender,
            recipient,
            bucket.amount - reward
        );

        channel.process();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyDAO {}

    modifier onlyDAO() {
        _;
    }
}
