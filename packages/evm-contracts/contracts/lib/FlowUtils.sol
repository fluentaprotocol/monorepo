// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {StorageUtils} from "./StorageUtils.sol";
import "hardhat/console.sol";

library FlowUtils {
    struct FlowData {
        address recipient;
        uint256 timestamp;
        uint256 rate;
    }

    struct FlowState {
        uint256 timestamp;
        uint256 deposit;
        uint256 accrue;
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
    string private constant STATE_NAMESPACE = "fluenta.state";

    uint256 internal constant USER_MAX_FLOWS = 256;
    uint256 internal constant FLOW_DATA_SIZE = 3;
    uint256 internal constant FLOW_STATE_SIZE = 4;

    /**************************************************************************
     * Flow controls
     *************************************************************************/
    function initiateFlow(
        bytes32 account,
        bytes32 recipient,
        uint256 bitmap,
        uint256 rate
    ) internal returns (bytes32 id, uint index) {
        index = _availableSlot(bitmap);
        id = _flowId(account, index);

        bytes32 slot = _flowDataSlot(id);
        uint256 timestamp = block.timestamp;

        bytes32[] memory data = _encodeFlowData(recipient, rate, timestamp);

        StorageUtils.store(slot, data);

        _increaseFlowState(account);

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
        bytes32 slot = _flowDataSlot(flow);

        FlowUtils.FlowData memory data = _decodeFlowData(flow);

        // Calculate the total amount streamed
        uint256 timestamp = block.timestamp;
        uint256 elapsed = timestamp - data.timestamp;
        int256 total = int256(elapsed * data.rate);

        StorageUtils.clear(slot, FlowUtils.FLOW_DATA_SIZE);

        // _updateFlowState(account, timestamp);

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
        bytes32 recipient,
        uint256 rate,
        uint256 timestamp
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory data = new bytes32[](FLOW_DATA_SIZE);

        data[0] = bytes32(recipient);
        data[1] = bytes32(rate);
        data[2] = bytes32(timestamp);

        return data;
    }

    function _encodeFlowState(
        uint256 timestamp,
        uint256 deposit,
        uint256 accrue,
        uint256 rate
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory data = new bytes32[](FLOW_STATE_SIZE);

        data[0] = bytes32(timestamp);
        data[1] = bytes32(deposit);
        data[2] = bytes32(accrue);
        data[3] = bytes32(rate);

        return data;
    }

    function _decodeFlowData(
        bytes32 flow
    ) private view returns (FlowData memory) {
        bytes32 slot = _flowDataSlot(flow);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_DATA_SIZE);

        return
            FlowData({
                recipient: address(uint160(uint256(data[0]))),
                timestamp: uint256(data[1]),
                rate: uint256(data[2])
            });
    }

    function _decodeFlowState(
        bytes32 account
    ) private view returns (FlowState memory) {
        bytes32 slot = _flowStateSlot(account);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_STATE_SIZE);

        return
            FlowState({
                timestamp: uint256(data[0]),
                deposit: uint256(data[1]),
                accrue: uint256(data[2]),
                rate: uint256(data[3])
            });
    }

    /**************************************************************************
     * FlowState util functions
     *************************************************************************/
    function _increaseFlowState(bytes32 account) private view {
        FlowState memory state = _decodeFlowState(account);

        uint256 timestamp = block.timestamp;

        uint256 elapsed = timestamp - state.timestamp;
        uint256 total = (state.rate * elapsed);

        // uint256 deposit = state.deposit + total;
        // uint256 accrue = state.accrue;
        // int256 rate = state.rate + rate;
    }

    function _decreaseFlowState(bytes32 account) private view {
        FlowState memory state = _decodeFlowState(account);

        uint256 timestamp = block.timestamp;

        uint256 elapsed = timestamp - state.timestamp;
        uint256 total = state.rate * elapsed;

        // uint256 deposit = state.deposit + total;
        // uint256 accrue = state.accrue;
        // int256 rate = state.rate + rate;
    }

    function _flowStateSlot(bytes32 account) private pure returns (bytes32) {
        return keccak256(abi.encode(FLOW_NAMESPACE, account));
    }

    /**************************************************************************
     * FlowData util functions
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

    function _flowDataSlot(bytes32 flow) private pure returns (bytes32) {
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

    // function _isRecipient(
    //     bytes32 flow,
    //     address account
    // ) private view returns (bool) {
    //     bytes32 slot = _flowDataSlot(flow);
    //     bytes32 recipient;

    //     assembly {
    //         recipient := sload(add(slot, 1))
    //     }

    //     return account == address(uint160(uint256(recipient)));
    // }
}
