// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.4;

// import {Storage} from "./Storage.sol";
import "hardhat/console.sol";

//  //   All required channel data is can be packed in a 2 * bytes32 storage
//  //   slots, this allows for gas optimization
//  //
//  //    ---------- ------------------ ------------------ ------------------
//  //   | SLOT   1 | provider    20b  | expired      8b  | endpoint     4b  |
//  //    ---------- ------------------ ------------------ ------------------
//  //   | SLOT   2 | account     20b  | updated      8b  |                  |
//  //    ---------- ------------------ ------------------ ------------------

// bytes32 provider 
// bytes20 account
// bytes4 bucket
// uint64 updated
// uint64 expired
// uint64 started

struct Channel {
    bytes32 provider;
    address account;
    uint64 expired;
    bytes4 bucket;
}

library ChannelUtils {
    //     // using Storage for bytes32;

    //     // error ChannelDoesNotExist(bytes32 channel);
    //     // error ChannelAlreadyExists(bytes32 channel) ;

    //     event ChannelClosed(bytes32 channel);

    //     uint constant CHANNEL_SLOT_COUNT = 2; // Data packed in 2 x bytes32 slots

    function open(
        Channel storage self,
        bytes32 provider,
        address account,
        uint64 expired,
        bytes4 bucket
    ) internal {
        self.provider = provider;
        self.account = account;
        self.expired = expired;
        self.bucket = bucket;
    }

    function close(Channel storage self) internal {
        delete self.provider;
        delete self.account;
        delete self.expired;
        delete self.bucket;
    }

    function process(Channel storage self) internal {
        // IFluentToken(bucket.token).transact(
        //     sender,
        //     recipient,
        //     bucket.amount - reward
        // );

    }

    function exists(Channel storage self) internal view returns (bool) {
        return
            self.provider != bytes32(0) ||
            self.account != address(0) ||
            self.bucket != bytes4(0) ||
            self.expired != 0;
    }
    //     function open(
    //         bytes32 channel,
    //         address provider,
    //         address account,
    //         uint64 expired,
    //         uint64 started,
    //         bytes4 bucket
    //     ) internal {
    //         bytes32[] memory data_ = new bytes32[](CHANNEL_SLOT_COUNT);

    //         data_[0] = bytes32(
    //             (uint256(uint160(provider)) << 96) |
    //                 (uint256(expired) << 32) |
    //                 uint256(uint32(bucket))
    //         );

    //         data_[1] = bytes32(
    //             (uint256(uint160(account)) << 96) | (uint256(started) << 32)
    //         );

    //         // Store the data back into the channel
    //         channel.sstore(data_);
    //     }

    //     function close(bytes32 channel) internal {
    //         channel.sclear(CHANNEL_SLOT_COUNT);

    //         emit ChannelClosed(channel);
    //     }

    //     function data(
    //         bytes32 channel
    //     )
    //         internal
    //         view
    //         returns (
    //             address provider,
    //             address account,
    //             uint64 expired,
    //             uint64 started,
    //             bytes4 bucket
    //         )
    //     {
    //         bytes32[] memory data_ = channel.sload(CHANNEL_SLOT_COUNT);

    //         bytes32 left = data_[0];
    //         bytes32 right = data_[1];

    //         assembly {
    //             provider := shr(96, left)
    //             account := shr(96, right)
    //             expired := shr(32, and(left, 0xFFFFFFFF00000000))
    //             started := shr(32, and(right, 0xFFFFFFFF00000000))
    //             // bucket := and(left, 0xFFFFFFFF)
    //         }

    //         // provider = address(uint160(uint256(data[0] >> 96)));
    //         // account = address(uint160(uint256(data[1] >> 96)));
    //         // expired = uint64(uint256(data[0] >> 32));
    //         // started = uint64(uint256(data[1] >> 32));
    //         bucket = bytes4(uint32(uint256(left)));
    //     }

    //     function exists(bytes32 channel) internal view returns (bool) {
    //         bytes32[] memory data_ = channel.sload(CHANNEL_SLOT_COUNT);

    //         return _isValid(data_[0], data_[1]);
    //     }

    //     function _isValid(
    //         bytes32 slotA,
    //         bytes32 slotB
    //     ) internal pure returns (bool) {
    //         return slotA != bytes32(0) && slotB != bytes32(0);
    //     }
}
