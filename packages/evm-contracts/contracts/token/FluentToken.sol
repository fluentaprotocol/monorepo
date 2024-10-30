// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {BaseToken} from "./BaseToken.sol";
import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {StorageUtils} from "../lib/StorageUtils.sol";

// uint256 constant MINUTE_INTERVAL = 60;
// uint256 constant HOURLY_INTERVAL = 3600; // 60 * 60
// uint256 constant DAILY_INTERVAL = 86400; // 24 * 60 * 60
// uint256 constant WEEKLY_INTERVAL = 604800; // 7 * 24 * 60 * 60
// uint256 constant MONTHLY_INTERVAL = 2592000; // (365 / 12) * 24 * 60 * 60
// uint256 constant YEARLY_INTERVAL = 31536000; // (365 * 24 * 60 * 60)

struct FlowData {
    address recipient;
    uint256 timestamp;
    uint256 rate;
}

contract FluentToken is IFluentToken, BaseToken, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeCast for uint256;
    using SafeCast for int256;

    string private constant USER_NAMESPACE = "fluenta.user";
    string private constant FLOW_NAMESPACE = "fluenta.flow";

    uint256 private constant FLOW_STORAGE_SIZE = 3;
    uint256 private constant MAX_STREAMS = 256;

    EnumerableSet.Bytes32Set private _flows;

    mapping(bytes32 => uint256) private _flowStates;

    function initialize(
        IERC20Metadata token,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __BaseToken_init(token, name_, symbol_);
        __UUPSUpgradeable_init();
    }

    /**************************************************************************
     * Stream functions
     *************************************************************************/
    function initiateFlow(address recipient, uint256 flowRate) external {
        address sender = _msgSender();
        bytes32 account = _accountId(sender);

        uint8 index = _nextFlowIndex(account);

        bytes32 id = _flowId(account, index);
        bytes32 slot = _flowStorage(id);

        bytes32[] memory data = new bytes32[](FLOW_STORAGE_SIZE);

        // // Store data in byte slots
        data[0] = bytes32(uint256(uint160(recipient)));
        data[1] = bytes32(flowRate);
        data[2] = bytes32(block.timestamp);

        // Store flow data
        StorageUtils.store(slot, data);

        // Add flow to register
        _flows.add(id);
        _flowStates[account] |= (1 << index);

        // emit StreamStarted(sender, recipient, streamIndex, flowRate, totalAmount);
    }

    function terminateFlow(bytes32 flow) external {
        address sender = _msgSender();
        bytes32 account = _accountId(sender);

        if (!_isFlowSender(flow, account)) {
            revert("user not owner of stream");
        }

        // Get the index of the flow
        uint8 index = _flowIndex(account, flow);

        // Get the actual data of the flow
        bytes32 slot = _flowStorage(flow);
        FlowData memory data = _flowData(flow);

        // Calculate the total amount streamed
        uint256 elapsed = block.timestamp - data.timestamp;
        int256 total = int256(elapsed * data.rate);

        // Update the balances of both the sender and recipient
        _balances[data.recipient] += total;
        _balances[sender] -= total;

        // Remove flow from register
        _flows.remove(flow);
        _flowStates[account] |= (1 << index);

        // Delete flow data
        StorageUtils.clear(slot, FLOW_STORAGE_SIZE);

        // emit StreamStopped(sender, streamIndex);
    }

    function mapAccountFlows(
        address user
    ) external view returns (bytes32[] memory) {
        bytes32 account = _accountId(user);
        uint256 bitmap = _flowStates[account];

        bytes32[] memory result = new bytes32[](MAX_STREAMS);

        uint8 i = 0;
        uint8 n = 0;

        while (i < MAX_STREAMS) {
            if ((bitmap & (1 << i)) != 0) {
                result[n++] = _flowId(account, i++);
            }
        }

        assembly {
            mstore(result, n)
        }

        return result;
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/
    function balanceOf(
        address account
    ) public view override(BaseToken, IERC20) returns (uint256) {
        int256 balance = _balances[account];

        return balance < 0 ? 0 : uint256(balance);
    }

    function timestampBalanceOf(address user) public view {
        bytes32 account = _accountId(user);

        for (uint i = 0; i < _flows.length(); i++) {
            bytes32 flow = _flows.at(i);

            if (_isFlowSender(flow, account) || _isFlowRecipient(flow, user)) {
                FlowData memory data = _flowData(flow);
                // bytes32 slot = _flowStorage(flow);
                // bytes32[] memory data = slot.loadData(FLOW_STORAGE_SIZE);

                //  account is sender or recipient
                //  load the stream data
                //
                // FlowData({
                //     recipient: address(uint160(uint256(data[0]))),
                //     timestamp: uint256(data[1]),
                //     rate: uint256(data[2])
                // });
                // StreamData memory data = _loadStreamData(_streams.at(i));
                // if (data.recipient == account || data.sender == account) {}
                // calculate balances
            }
        }
    }

    /**************************************************************************
     * Flow helper functions
     *************************************************************************/
    function _accountId(address user) private pure returns (bytes32) {
        return keccak256(abi.encode(USER_NAMESPACE, user));
    }

    // Calculate the flow id based on index
    function _flowId(
        bytes32 account,
        uint8 index
    ) private pure returns (bytes32 slot) {
        assembly {
            slot := add(account, add(index, 1))
        }
    }

    // Calculate the index based on flow id
    function _flowIndex(
        bytes32 account,
        bytes32 flow
    ) private pure returns (uint8 index) {
        assembly {
            index := sub(sub(flow, account), 1)
        }
    }

    // Calculate the flow id based on index
    function _flowData(bytes32 flow) private view returns (FlowData memory) {
        bytes32 slot = _flowStorage(flow);
        bytes32[] memory data = StorageUtils.load(slot, FLOW_STORAGE_SIZE);

        return
            FlowData({
                recipient: address(uint160(uint256(data[0]))),
                timestamp: uint256(data[1]),
                rate: uint256(data[2])
            });
    }

    // Find the next availble flow slot for this account
    function _nextFlowIndex(bytes32 account) private view returns (uint8) {
        uint256 bitmap = _flowStates[account];

        for (uint8 i = 0; i < MAX_STREAMS; i++) {
            if ((bitmap & (1 << i)) == 0) {
                return i;
            }
        }

        revert("No available slot");
    }

    // Calculate the storage slot for this flow
    function _flowStorage(bytes32 flow) private pure returns (bytes32) {
        return keccak256(abi.encode(FLOW_NAMESPACE, flow));
    }

    // Checks if account is sender of flow
    function _isFlowSender(
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

    // Checks if account is recipient of flow
    function _isFlowRecipient(
        bytes32 flow,
        address account
    ) internal view returns (bool) {
        bytes32 slot = _flowStorage(flow);
        bytes32 recipient;

        assembly{
            recipient := sload(add(slot, 1))
        }

        return account == address(uint160(uint256(recipient)));
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(address newImplementation) internal override {}
}
