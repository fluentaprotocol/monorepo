// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.4;

import {Interval, IntervalUtils} from "./Interval.sol";
import {DateTimeUtils} from "./DateTime.sol";
import {IFluentProvider} from "../interfaces/IFluentProvider.sol";
import {IFluentToken} from "../interfaces/IFluentToken.sol";

struct Channel {
    bytes32 provider;
    address account;
    uint64 expired;
    bytes4 bucket;
}

library ChannelUtils {
    using DateTimeUtils for *;
    using IntervalUtils for *;

    function open(
        Channel storage self,
        IFluentProvider provider,
        address account,
        bytes32 providerId,
        bytes4 bucketId,
        uint fee
    ) internal {
        (
            uint256 total,
            address token,
            address recipient,
            Interval interval
        ) = provider.getBucket(providerId, bucketId);

        (uint value, uint discounted) = _feeValue(total, fee, 0);
        IFluentToken(token).transact(account, recipient, value, discounted);

        self.provider = providerId;
        self.account = account;
        self.expired = interval.next(block.timestamp);
        self.bucket = bucketId;
    }

    function close(Channel storage self) internal {
        delete self.provider;
        delete self.account;
        delete self.expired;
        delete self.bucket;
    }

    function process(
        Channel storage self,
        IFluentProvider provider,
        address processor,
        uint64 gracePeriod,
        uint256 minReward,
        uint256 maxReward,
        uint256 maxFee
    ) internal {
        (
            uint256 total,
            address token,
            address recipient,
            Interval interval
        ) = provider.getBucket(self.provider, self.bucket);

        uint256 reward;
        uint256 discount;

        unchecked {
            uint256 progress = ((block.timestamp -
                (self.expired - gracePeriod)) * 100_000) / gracePeriod;

            uint256 rewardMul = minReward +
                (((maxReward - minReward) * progress) / 100_000);

            reward = (total * rewardMul) / 100_000;
        }

        (uint value, uint fee) = _feeValue(total, maxFee, discount);

        IFluentToken(token).transactFor(
            processor,
            self.account,
            recipient,
            value,
            reward,
            fee
        );

        self.expired = interval.next(self.expired);
    }

    function exists(Channel storage self) internal view returns (bool) {
        return
            self.provider != bytes32(0) ||
            self.account != address(0) ||
            self.bucket != bytes4(0) ||
            self.expired != 0;
    }

    function isLocked(
        Channel storage self,
        uint grace
    ) internal view returns (bool) {
        return block.timestamp < self.expired - grace;
    }

    function isExpired(Channel storage self) internal view returns (bool) {
        return block.timestamp >= self.expired;
    }

    function _feeValue(
        uint256 total,
        uint256 fee,
        uint256 discount
    ) private pure returns (uint256 value, uint feed) {
        unchecked {
            uint max = (total * fee) / 100_000;
            uint discounted = (total * discount) / 100_000;

            value = total - max;
            feed = max - discounted;
        }
    }
}
