// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";

import {FlowUtils} from "../lib/FlowUtils.sol";
import {AccountUtils} from "../lib/AccountUtils.sol";

contract FluentToken is IFluentToken, UUPSUpgradeable, ContextUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AccountUtils for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20Metadata private _underlying;

    string private _symbol;
    string private _name;

    uint256 private _totalSupply;

    mapping(bytes32 => uint256) private _states;
    mapping(address => int256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    EnumerableSet.Bytes32Set private _flows;

    function initialize(
        IERC20Metadata token_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        _name = name_;
        _symbol = symbol_;
        _underlying = token_;

        __Context_init();
        __UUPSUpgradeable_init();
    }

    /**************************************************************************
     * Token meta functions
     *************************************************************************/
    function decimals() public pure returns (uint8) {
        return 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function underlying() external view returns (address) {
        return address(_underlying);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**************************************************************************
     * Token wrapper functions
     *************************************************************************/
    function deposit(uint256 value) external {
        address sender = _msgSender();

        if (sender == address(this)) {
            revert ERC20InvalidSender(address(this));
        }

        SafeERC20.safeTransferFrom(_underlying, sender, address(this), value);
        _mint(sender, value);
    }

    function withdraw(uint256 value) external {
        address recipient = _msgSender();

        _burn(recipient, value);
        SafeERC20.safeTransfer(_underlying, recipient, value);
    }

    /**************************************************************************
     * Stream functions
     *************************************************************************/
    function initiateFlow(address recipient, uint256 rate) external {
        address sender = _msgSender();

        bytes32 account = sender.account();
        uint256 bitmap = _states[account];

        (bytes32 id, uint8 index) = FlowUtils.initiateFlow(
            account,
            bitmap,
            recipient,
            rate
        );

        // Add flow to register
        _flows.add(id);
        _states[account] |= (1 << index);

        // emit StreamStarted(sender, recipient, streamIndex, flowRate, totalAmount);
    }

    function terminateFlow(bytes32 flow) external {
        address sender = _msgSender();
        bytes32 account = sender.account();

        (address recipient, uint8 index, int256 total) = FlowUtils
            .terminateFlow(account, flow);

        // Update the balances of both the sender and recipient
        _balances[recipient] += total;
        _balances[sender] -= total;

        // Remove flow from register
        _flows.remove(flow);
        _states[account] |= (1 << index);

        // emit StreamStopped(sender, streamIndex);
    }

    /**************************************************************************
     * Balance functions
     *************************************************************************/
    function balanceOf(address account) public view returns (uint256) {
        int256 balance = _balances[account];

        return balance < 0 ? 0 : uint256(balance);
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function timestampBalanceOf() public view /* address user */ {
        // bytes32 account = user.account();

        for (uint i = 0; i < _flows.length(); i++) {
            // bytes32 flow = _flows.at(i);
            // if (
            //     FlowUtils.isSender(flow, account) ||
            //     FlowUtils.isRecipient(flow, user)
            // ) {
            //     FlowUtils.FlowData memory data = FlowUtils.flowData(flow);
            //     // bytes32 slot = _flowStorage(flow);
            //     // bytes32[] memory data = slot.loadData(FLOW_STORAGE_SIZE);
            //     //  account is sender or recipient
            //     //  load the stream data
            //     //
            //     // FlowData({
            //     //     recipient: address(uint160(uint256(data[0]))),
            //     //     timestamp: uint256(data[1]),
            //     //     rate: uint256(data[2])
            //     // });
            //     // StreamData memory data = _loadStreamData(_streams.at(i));
            //     // if (data.recipient == account || data.sender == account) {}
            //     // calculate balances
            // }
        }
    }

    /**************************************************************************
     * Token transfer / approve functions
     *************************************************************************/
    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(_msgSender(), to, value.toInt256());

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value.toInt256());

        return true;
    }

    /**************************************************************************
     * Token helper functions
     *************************************************************************/
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _balances[account] = _balances[account] + value.toInt256();
        _totalSupply = _totalSupply + value;
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        uint256 balance = balanceOf(account);

        if (balance < value) {
            revert ERC20InsufficientBalance(account, balance, value);
        }

        _balances[account] = _balances[account] - value.toInt256();
        _totalSupply = _totalSupply - value;
    }

    function _transfer(
        address from,
        address to,
        int256 amount
    ) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }

        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }

        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(address newImplementation) internal override {}
}
