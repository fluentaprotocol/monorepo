// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

// import {Encoder} from "./Encoder.sol";
// import {Bitmap} from "./Bitmap.sol";
// import {Storage} from "./Storage.sol";
// import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// import "hardhat/console.sol";

// // 1. The higher the rate in the flow state, the more money is going out
// // 2. If the flow state rate is below 0, there is more money coming in then going out.

// library Stream {
//     using Bitmap for uint256;
//     using SafeCast for uint256;
//     using SafeCast for int256;

//     struct FlowData {
//         address recipient;
//         uint256 timestamp;
//         uint256 rate;
//     }

//     struct FlowState {
//         uint256 timestamp;
//         uint256 deposit; // the amount that we sent out
//         uint256 accrue; // the amount that comes in
//         int256 rate;
//     }

//     // uint256 constant MINUTE_INTERVAL = 60;
//     // uint256 constant HOURLY_INTERVAL = 3600; // 60 * 60
//     // uint256 constant DAILY_INTERVAL = 86400; // 24 * 60 * 60
//     // uint256 constant WEEKLY_INTERVAL = 604800; // 7 * 24 * 60 * 60
//     // uint256 constant MONTHLY_INTERVAL = 2592000; // (365 / 12) * 24 * 60 * 60
//     // uint256 constant YEARLY_INTERVAL = 31536000; // (365 * 24 * 60 * 60)

//     string private constant USER_NAMESPACE = "fluenta.user";
//     string private constant FLOW_NAMESPACE = "fluenta.flow";
//     string private constant STATE_NAMESPACE = "fluenta.state";

//     uint256 internal constant FLOW_DATA_SIZE = 3;
//     uint256 internal constant FLOW_STATE_SIZE = 4;
//     uint256 internal constant USER_MAX_FLOWS = 256;

//     /**************************************************************************
//      * Account functions
//      *************************************************************************/
//     function account(address user) internal pure returns (bytes32) {
//         return keccak256(abi.encode(USER_NAMESPACE, user));
//     }

//     /**************************************************************************
//      * Flow controls
//      *************************************************************************/
//     function initiateFlow(
//         bytes32 account_,
//         bytes32 recipient,
//         uint256 bitmap,
//         uint256 rate
//     ) internal returns (bytes32, uint) {
//         (bool available, uint index) = bitmap.nextInactive();

//         if (!available) {
//             revert("no available slot");
//         }

//         bytes32 id = _flowId(account_, index);

//         uint256 timestamp = block.timestamp;
//         bytes32[] memory data = _encodeFlowData(recipient, rate, timestamp);

//         _updateFlowState(recipient, rate.toInt256());
//         _updateFlowState(recipient, -(rate.toInt256()));

//         bytes32 slot = _flowDataSlot(id);
//         Storage.store(slot, data);

//         return (id, index);
//     }

//     function terminateFlow(
//         bytes32 account_,
//         bytes32 flow
//     ) internal returns (address, uint, int256) {
//         if (!_isSender(flow, account_)) {
//             revert("user not owner of stream");
//         }

//         // Get the index of the flow
//         uint index = _flowIndex(account_, flow);
//         bytes32 slot = _flowDataSlot(flow);

//         FlowData memory data = _decodeFlowData(flow);

//         // Calculate the total amount streamed
//         uint256 timestamp = block.timestamp;
//         uint256 elapsed = timestamp - data.timestamp;
//         int256 total = int256(elapsed * data.rate);

//         Storage.clear(slot, FLOW_DATA_SIZE);

//         // _updateFlowState(account, timestamp);

//         return (data.recipient, index, total);
//     }

//     function accountFlows(
//         bytes32 account_,
//         uint256 bitmap
//     ) internal pure returns (bytes32[] memory) {
//         bytes32[] memory result = new bytes32[](USER_MAX_FLOWS);

//         uint i = 0;
//         uint n = 0;

//         while (i < USER_MAX_FLOWS) {
//             if ((bitmap & (1 << i)) != 0) {
//                 result[n++] = _flowId(account_, i);
//             }

//             unchecked {
//                 i++;
//             }
//         }

//         assembly {
//             mstore(result, n)
//         }

//         return result;
//     }

//     /**************************************************************************
//      * FlowData util functions
//      *************************************************************************/
//     function _encodeFlowData(
//         bytes32 recipient,
//         uint256 rate,
//         uint256 timestamp
//     ) private pure returns (bytes32[] memory) {
//         bytes32[] memory data = new bytes32[](FLOW_DATA_SIZE);

//         data[0] = bytes32(recipient);
//         data[1] = bytes32(rate);
//         data[2] = bytes32(timestamp);

//         return data;
//     }

//     function _decodeFlowData(
//         bytes32 flow
//     ) private view returns (FlowData memory) {
//         bytes32 slot = _flowDataSlot(flow);
//         bytes32[] memory data = Storage.load(slot, FLOW_DATA_SIZE);

//         return
//             FlowData({
//                 recipient: address(uint160(uint256(data[0]))),
//                 timestamp: uint256(data[1]),
//                 rate: uint256(data[2])
//             });
//     }

//     function _flowDataSlot(bytes32 flow) private pure returns (bytes32) {
//         return keccak256(abi.encode(FLOW_NAMESPACE, flow));
//     }

//     /**************************************************************************
//      * FlowState util functions
//      *************************************************************************/

//     /// @dev Record and increase / decrease the outgoing flow rate.
//     function _updateFlowState(bytes32 account_, int256 rate) private {
//         FlowState memory state = _recordFlowState(account_);
//         bytes32 slot = _flowStateSlot(account_);

//         bytes32[] memory data = _encodeFlowState(
//             state.timestamp,
//             state.deposit,
//             state.accrue,
//             state.rate + rate
//         );

//         Storage.store(slot, data);
//     }

//     /// @dev After termination of flow, we can trim the flow state to make room in the deposit and accrue.
//     function _trimFlowState(bytes32 account_) private {}

//     /// @dev Load the flow data and calculate the balance at timestamp
//     function _recordFlowState(
//         bytes32 account_
//     ) private view returns (FlowState memory state) {
//         state = _decodeFlowState(account_);

//         uint256 timestamp = block.timestamp;

//         int256 elapsed = (timestamp - state.timestamp).toInt256();
//         int256 total = state.rate * elapsed;

//         // If total >= 0, we had more going out than coming in.
//         if (total >= 0) {
//             state.deposit = state.deposit + total.toUint256();
//         } else {
//             state.accrue = state.accrue + total.toUint256();
//         }

//         state.timestamp = timestamp;
//     }

//     function _encodeFlowState(
//         uint256 timestamp,
//         uint256 deposit,
//         uint256 accrue,
//         int256 rate
//     ) private pure returns (bytes32[] memory) {
//         bytes32[] memory data = new bytes32[](FLOW_STATE_SIZE);

//         data[0] = bytes32(timestamp);
//         data[1] = bytes32(deposit);
//         data[2] = bytes32(accrue);
//         data[3] = Encoder.encodeInt256(rate);

//         return data;
//     }

//     function _decodeFlowState(
//         bytes32 account_
//     ) private view returns (FlowState memory) {
//         bytes32 slot = _flowStateSlot(account_);
//         bytes32[] memory data = Storage.load(slot, FLOW_STATE_SIZE);

//         return
//             FlowState({
//                 timestamp: uint256(data[0]),
//                 deposit: uint256(data[1]),
//                 accrue: uint256(data[2]),
//                 rate: Encoder.decodeInt256(data[3])
//             });
//     }

//     function _flowStateSlot(bytes32 account_) private pure returns (bytes32) {
//         return keccak256(abi.encode(FLOW_NAMESPACE, account_));
//     }

//     /**************************************************************************
//      * FlowData util functions
//      *************************************************************************/
//     function _flowId(
//         bytes32 account_,
//         uint index
//     ) private pure returns (bytes32 slot) {
//         assembly {
//             slot := add(account_, add(index, 1))
//         }
//     }

//     function _flowSeed() private pure returns (bytes32 slot) {}

//     function _flowIndex(
//         bytes32 account_,
//         bytes32 flow
//     ) private pure returns (uint index) {
//         assembly {
//             index := sub(sub(flow, account_), 1)
//         }
//     }

//     // function _availableSlot(uint256 bitmap) private pure returns (uint) {
//     //     for (uint i = 0; i < FlowUtils.USER_MAX_FLOWS; i++) {
//     //         if ((bitmap & (1 << i)) == 0) {
//     //             return i;
//     //         }
//     //     }

//     //     revert("No available slot");
//     // }

//     function _isSender(
//         bytes32 flow,
//         bytes32 account_
//     ) private pure returns (bool) {
//         bytes32 min;
//         bytes32 max;

//         assembly {
//             min := add(account_, 1)
//             max := add(account_, USER_MAX_FLOWS)
//         }

//         return (flow >= min && flow <= max);
//     }

//     // function _isRecipient(
//     //     bytes32 flow,
//     //     address account
//     // ) private view returns (bool) {
//     //     bytes32 slot = _flowDataSlot(flow);
//     //     bytes32 recipient;

//     //     assembly {
//     //         recipient := sload(add(slot, 1))
//     //     }

//     //     return account == address(uint160(uint256(recipient)));
//     // }
// }
