// // SPDX-License-Identifier: AGPLv3
// pragma solidity ^0.8.27;

// import {Storage} from "./Storage.sol";

// //      The stream data is packed into 3 x 32 bytes slots minimal gas usage and maximum
// //      efficiency.
// //
// //      address account 20b
// //      uint64 expired 8b
// //      uint64 interval 20b


// //      address account;
// //      uint64 start; 
// //      bytes4 bucket; 
// //      address token;
// //      uint64 expired; 
// //      uint32 interval; 
// //      uint128 amount; 
// //      uint128 buffer; 
// //
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     // SLOT 1: |               account               |      start       |      bucket      |
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     //         |                 20b                 |        8b        |        4b        |
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     // SLOT 2: |                token                |      expired     |     interval     |
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     //         |                 20b                 |        8b        |        4b        |
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     // SLOT 3: |                amount               |                buffer               |
// //     // -------- ------------------ ------------------ ------------------ ------------------
// //     //         |                 16b                 |                 16b                 |
// //     // -------- ------------------ ------------------ ------------------ ------------------

// library Stream {
//     using Storage for bytes32;

//     uint constant STREAM_SLOT_COUNT = 3; // Data packed in 3 x bytes32 slots
//     uint constant STREAM_UNLOCK_PERIOD = 48 hours;
//     uint constant PROCESS_UNLOCK_PERIOD = 48 * 60 * 60; // 48 Hours

//     function _pack(
//         address account,
//         address token,
//         uint64 start,
//         uint64 expired
//     ) private pure returns (bytes32[] memory data) {}

//     function _process() private {
//         address account;
//         address token;
//         uint256 amount;

//         uint64 expired;
//         uint64 unlocked = expired - (48 hours);

//         if (block.timestamp >= expired) {
//             revert("expired");
//         }
//     }

//     function _store(bytes32 slot, address account, address token) private {
//         bytes32[] memory data = new bytes32[](STREAM_SLOT_COUNT);

//         uint64 start = uint64(block.timestamp);
//         uint64 interval = uint64(0);
//         uint64 expired = start + interval;

//         // Pack account, start, and first 4 bytes of interval into the first slot
//         data[0] = bytes32(
//             (uint256(uint160(account)) << 96) | // Shift account address to the leftmost 20 bytes
//                 (uint256(start) << 32) | // Shift start to the next 8 bytes
//                 (uint256(interval) >> 32) // Use the first 4 bytes of interval
//         );

//         // Pack token, remaining 4 bytes of interval, and expired into the second slot
//         data[1] = bytes32(
//             (uint256(uint160(token)) << 96) | // Shift token address to the leftmost 20 bytes
//                 ((uint256(interval) & 0xFFFFFFFF) << 64) | // Use the remaining 4 bytes of interval
//                 (uint256(expired) >> 32) // Shift expired to the next 8 bytes
//         );

//         slot.store(data);
//     }

//     function _load(
//         bytes32
//     ) private view returns (address account, address token, uint amount) {
//         // bytes32[] memory data = slot.load(STREAM_SLOT_COUNT);
//     }
// }
