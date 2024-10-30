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

    string private constant USER_NAMESPACE = "fluenta.user";
    string private constant FLOW_NAMESPACE = "fluenta.flow";

    uint256 private constant MAX_STREAMS = 256;
    uint256 private constant FLOW_STORAGE_SIZE = 3;

    function accountId(address user) public pure returns (bytes32) {
        return keccak256(abi.encode(USER_NAMESPACE, user));
    }

    function flowId(
        bytes32 account,
        uint8 index
    ) public pure returns (bytes32 slot) {
        assembly {
            slot := add(account, add(index, 1))
        }
    }

    function flowIndex(
        bytes32 account,
        bytes32 flow
    ) public pure returns (uint8 index) {
        assembly {
            index := sub(sub(flow, account), 1)
        }
    }

    function flowData(bytes32 flow) public view returns (FlowData memory) {
        bytes32 slot = flowStorage(flow);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_STORAGE_SIZE);

        return
            FlowData({
                recipient: address(uint160(uint256(data[0]))),
                timestamp: uint256(data[1]),
                rate: uint256(data[2])
            });
    }

    function flowStorage(bytes32 flow) public pure returns (bytes32) {
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
            max := add(account, MAX_STREAMS)
        }

        return (flow >= min && flow <= max);
    }

    function isRecipient(
        bytes32 flow,
        address account
    ) public view returns (bool) {
        bytes32 slot = flowStorage(flow);
        bytes32 recipient;

        assembly {
            recipient := sload(add(slot, 1))
        }

        return account == address(uint160(uint256(recipient)));
    }
}
