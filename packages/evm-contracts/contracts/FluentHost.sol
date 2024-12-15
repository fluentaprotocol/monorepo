// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IFluentDao} from "./interfaces/IFluentDao.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {Channel, ChannelUtils} from "./libraries/Channel.sol";
import {Bucket, BucketUtils} from "./libraries/Bucket.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {IFluentHost} from "./interfaces/IFluentHost.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {IFluentTokenFactory} from "./interfaces/IFluentTokenFactory.sol";

import "hardhat/console.sol";

contract FluentHost is IFluentHost, UUPSUpgradeable, ContextUpgradeable {
    using ChannelUtils for Channel;
    using BucketUtils for Bucket;

    uint32 private constant FEE = 8_000; // 8%

    uint64 public gracePeriod;
    uint256 public minReward;
    uint256 public maxReward;

    IFluentDao public dao;
    IFluentProvider public provider;

    error ChannelLocked(bytes32 channel);
    error ChannelUnauthorized(address account);
    error ChannelDoesNotExist(bytes32 channel);
    error ChannelAlreadyExists(bytes32 channel);

    mapping(bytes32 => Channel) _channels;

    function initialize(
        uint64 gracePeriod_,
        uint256 minReward_,
        uint256 maxReward_,
        IFluentDao dao_,
        IFluentProvider provider_
    ) external initializer {
        minReward = minReward_;
        maxReward = maxReward_;
        gracePeriod = gracePeriod_;

        dao = dao_;
        provider = provider_;

        __Context_init();
        __UUPSUpgradeable_init();
    }

    function getChannel(bytes32 id) external view returns (Channel memory) {
        Channel storage channel = _channels[id];

        if (!channel.exists()) {
            revert ChannelDoesNotExist(id);
        }

        return channel;
    }

    function openChannel(
        bytes32 providerId,
        bytes4 bucketId
    ) external returns (bytes32) {
        address account = _msgSender();
        bytes32 id = keccak256(abi.encode(providerId, account));

        Channel storage channel = _channels[id];

        if (channel.exists()) {
            revert ChannelAlreadyExists(id);
        }

        channel.open(provider, account, providerId, bucketId, FEE);

        return id;
    }

    function closeChannel(bytes32 id) external {
        address account = _msgSender();
        Channel storage channel = _channels[id];

        if (!channel.exists()) {
            revert ChannelDoesNotExist(id);
        }

        if (channel.account != account) {
            revert ChannelUnauthorized(account);
        }

        channel.close();
    }

    function processChannel(bytes32 id) external {
        address processor = _msgSender();
        Channel storage channel = _channels[id];

        if (!channel.exists()) {
            revert ChannelDoesNotExist(id);
        }

        if (channel.isLocked(gracePeriod)) {
            revert ChannelLocked(id);
        }

        channel.process(
            provider,
            processor,
            gracePeriod,
            minReward,
            maxReward,
            FEE
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyDAO {}

    modifier onlyDAO() {
        _;
    }
}
