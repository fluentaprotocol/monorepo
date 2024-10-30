// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {StorageUtils} from "./StorageUtils.sol";

library FlowUtils {
    struct FlowData {
        address recipient;
        uint256 timestamp;
        uint256 rate;
    }

    // uint256 constant MINUTE_INTERVAL = 60;
    // uint256 constant HOURLY_INTERVAL = 3600; // 60 * 60
    // uint256 constant DAILY_INTERVAL = 86400; // 24 * 60 * 60
    // uint256 constant WEEKLY_INTERVAL = 604800; // 7 * 24 * 60 * 60
    // uint256 constant MONTHLY_INTERVAL = 2592000; // (365 / 12) * 24 * 60 * 60
    // uint256 constant YEARLY_INTERVAL = 31536000; // (365 * 24 * 60 * 60)

    // string private constant USER_NAMESPACE = "fluenta.user";
    string private constant FLOW_NAMESPACE = "fluenta.flow";

    uint256 internal constant USER_MAX_STREAMS = 256;
    uint256 internal constant FLOW_STORAGE_SIZE = 3;

    // // Account functions
    // function accountId(address user) internal pure returns (bytes32) {
    //     return keccak256(abi.encode(USER_NAMESPACE, user));
    // }

    // stream functions

    function initiateFlow(
        bytes32 account,
        uint256 bitmap,
        address recipient,
        uint256 rate
    ) internal returns (bytes32, uint8) {
        uint8 index = 0;

        bytes32 id = flowId(account, index);
        bytes32 slot = flowStorage(id);
        bytes32[] memory data = encodeFlowData(recipient, rate, block.timestamp);

        StorageUtils.store(slot, data);

        return (id, index);
    }

    // Encoding / Decoding
    function encodeFlowData(
        address recipient,
        uint256 rate,
        uint256 timestamp
    ) private view returns (bytes32[] memory) {
        bytes32[] memory data = new bytes32[](FLOW_STORAGE_SIZE);

        data[0] = bytes32(uint256(uint160(recipient)));
        data[1] = bytes32(rate);
        data[2] = bytes32(timestamp);

        return data;
    }

    function decodeFlowData() internal {}

    function flowId(
        bytes32 account,
        uint8 index
    ) internal pure returns (bytes32 slot) {
        assembly {
            slot := add(account, add(index, 1))
        }
    }

    function flowIndex(
        bytes32 account,
        bytes32 flow
    ) internal pure returns (uint8 index) {
        assembly {
            index := sub(sub(flow, account), 1)
        }
    }

    function flowData(bytes32 flow) internal view returns (FlowData memory) {
        bytes32 slot = flowStorage(flow);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_STORAGE_SIZE);

        return
            FlowData({
                recipient: address(uint160(uint256(data[0]))),
                timestamp: uint256(data[1]),
                rate: uint256(data[2])
            });
    }

    function flowStorage(bytes32 flow) internal pure returns (bytes32) {
        return keccak256(abi.encode(FLOW_NAMESPACE, flow));
    }

    function isSender(
        bytes32 flow,
        bytes32 account
    ) internal pure returns (bool) {
        bytes32 min;
        bytes32 max;

        assembly {
            min := add(account, 1)
            max := add(account, USER_MAX_STREAMS)
        }

        return (flow >= min && flow <= max);
    }

    function isRecipient(
        bytes32 flow,
        address account
    ) internal view returns (bool) {
        bytes32 slot = flowStorage(flow);
        bytes32 recipient;

        assembly {
            recipient := sload(add(slot, 1))
        }

        return account == address(uint160(uint256(recipient)));
    }
}
