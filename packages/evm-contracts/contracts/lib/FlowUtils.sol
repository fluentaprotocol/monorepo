// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {StorageUtils} from "./StorageUtils.sol";
import 'hardhat/console.sol';

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

    uint256 internal constant USER_MAX_FLOWS = 256;
    uint256 internal constant FLOW_STORAGE_SIZE = 3;

    /**************************************************************************
     * Flow controls
     *************************************************************************/
    function initiateFlow(
        bytes32 account,
        uint256 bitmap,
        address recipient,
        uint256 rate
    ) internal returns (bytes32 id, uint index) {
        index = _availableSlot(bitmap);
        id = _flowId(account, index);

        bytes32 slot = _flowStorage(id);
        bytes32[] memory data = _encodeFlowData(
            recipient,
            rate,
            block.timestamp
        );

        StorageUtils.store(slot, data);

        return (id, index);
    }

    function terminateFlow(
        bytes32 account,
        bytes32 flow
    ) internal returns (address, uint, int256) {
        if (!_isSender(flow, account)) {
            revert("user not owner of stream");
        }

        // Get the index of the flow
        uint index = _flowIndex(account, flow);
        bytes32 slot = _flowStorage(flow);

        FlowUtils.FlowData memory data = _decodeFlowData(flow);

        // Calculate the total amount streamed
        uint256 elapsed = block.timestamp - data.timestamp;
        int256 total = int256(elapsed * data.rate);

        StorageUtils.clear(slot, FlowUtils.FLOW_STORAGE_SIZE);

        return (data.recipient, index, total);
    }

    function accountFlows(
        bytes32 account,
        uint256 bitmap
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](USER_MAX_FLOWS);

        uint i = 0;
        uint n = 0;

        while (i < USER_MAX_FLOWS) {
            if ((bitmap & (1 << i)) != 0) {
                result[n++] = _flowId(account, i);
            }

            unchecked {
                i++;
            }
        }

        assembly {
            mstore(result, n)
        }

        return result;
    }

    /**************************************************************************
     * Encode / Decode
     *************************************************************************/
    function _encodeFlowData(
        address recipient,
        uint256 rate,
        uint256 timestamp
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory data = new bytes32[](FLOW_STORAGE_SIZE);

        data[0] = bytes32(uint256(uint160(recipient)));
        data[1] = bytes32(rate);
        data[2] = bytes32(timestamp);

        return data;
    }

    function _decodeFlowData(
        bytes32 flow
    ) private view returns (FlowData memory) {
        bytes32 slot = _flowStorage(flow);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_STORAGE_SIZE);

        return
            FlowData({
                recipient: address(uint160(uint256(data[0]))),
                timestamp: uint256(data[1]),
                rate: uint256(data[2])
            });
    }

    /**************************************************************************
     * Helper functions
     *************************************************************************/
    function _flowId(
        bytes32 account,
        uint index
    ) private pure returns (bytes32 slot) {
        assembly {
            slot := add(account, add(index, 1))
        }
    }

    function _flowIndex(
        bytes32 account,
        bytes32 flow
    ) private pure returns (uint index) {
        assembly {
            index := sub(sub(flow, account), 1)
        }
    }

    function _flowStorage(bytes32 flow) private pure returns (bytes32) {
        return keccak256(abi.encode(FLOW_NAMESPACE, flow));
    }

    function _availableSlot(uint256 bitmap) private pure returns (uint) {
        for (uint i = 0; i < FlowUtils.USER_MAX_FLOWS; i++) {
            if ((bitmap & (1 << i)) == 0) {
                return i;
            }
        }

        revert("No available slot");
    }

    function _isSender(
        bytes32 flow,
        bytes32 account
    ) private pure returns (bool) {
        bytes32 min;
        bytes32 max;

        assembly {
            min := add(account, 1)
            max := add(account, USER_MAX_FLOWS)
        }

        return (flow >= min && flow <= max);
    }

    function _isRecipient(
        bytes32 flow,
        address account
    ) private view returns (bool) {
        bytes32 slot = _flowStorage(flow);
        bytes32 recipient;

        assembly {
            recipient := sload(add(slot, 1))
        }

        return account == address(uint160(uint256(recipient)));
    }
}
