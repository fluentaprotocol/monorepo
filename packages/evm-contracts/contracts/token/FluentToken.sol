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
import {FlowUtils} from "../lib/FlowUtils.sol";
import {AccountUtils} from "../lib/AccountUtils.sol";

contract FluentToken is IFluentToken, BaseToken, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AccountUtils for address;
    using SafeCast for uint256;
    using SafeCast for int256;

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
    function initiateFlow(address recipient, uint256 rate) external {
        address sender = _msgSender();

        bytes32 account = sender.account();
        uint256 bitmap = _flowStates[account];

        (bytes32 id, uint8 index) = FlowUtils.initiateFlow(account, bitmap, recipient, rate);

        // Add flow to register
        _flows.add(id);
        _flowStates[account] |= (1 << index);

        // emit StreamStarted(sender, recipient, streamIndex, flowRate, totalAmount);
    }

    function terminateFlow(bytes32 flow) external {
        address sender = _msgSender();
        bytes32 account = sender.account();

        if (!FlowUtils.isSender(flow, account)) {
            revert("user not owner of stream");
        }

        // Get the index of the flow
        uint8 index = FlowUtils.flowIndex(account, flow);

        // Get the actual data of the flow
        bytes32 slot = FlowUtils.flowStorage(flow);
        FlowUtils.FlowData memory data = FlowUtils.flowData(flow);

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
        StorageUtils.clear(slot, FlowUtils.FLOW_STORAGE_SIZE);

        // emit StreamStopped(sender, streamIndex);
    }

    function mapAccountFlows(
        address user
    ) external view returns (bytes32[] memory) {
        bytes32 account = user.account();
        uint256 bitmap = _flowStates[account];

        bytes32[] memory result = new bytes32[](FlowUtils.USER_MAX_STREAMS);

        uint8 i = 0;
        uint8 n = 0;

        while (i < FlowUtils.USER_MAX_STREAMS) {
            if ((bitmap & (1 << i)) != 0) {
                result[n++] = FlowUtils.flowId(account, i++);
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
        bytes32 account = user.account();

        for (uint i = 0; i < _flows.length(); i++) {
            bytes32 flow = _flows.at(i);

            if (
                FlowUtils.isSender(flow, account) ||
                FlowUtils.isRecipient(flow, user)
            ) {
                FlowUtils.FlowData memory data = FlowUtils.flowData(flow);


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

    // Find the next availble flow slot for this account
    function _nextFlowIndex(bytes32 account) private view returns (uint8) {
        uint256 bitmap = _flowStates[account];

        for (uint8 i = 0; i < FlowUtils.USER_MAX_STREAMS; i++) {
            if ((bitmap & (1 << i)) == 0) {
                return i;
            }
        }

        revert("No available slot");
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(address newImplementation) internal override {}
}
