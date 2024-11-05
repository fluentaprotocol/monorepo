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
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {Bitmap} from "../lib/Bitmap.sol";
import {Account} from "../lib/Account.sol";

import "hardhat/console.sol";

contract FluentToken is IFluentToken, FluentHostable, UUPSUpgradeable {
    using SafeERC20 for IERC20Metadata;

    string public symbol;
    string public name;

    uint8 public decimals;
    uint256 public totalSupply;

    IERC20Metadata public underlying;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function initialize(
        IFluentHost host_,
        IERC20Metadata token_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        name = name_;
        symbol = symbol_;
        underlying = token_;

        decimals = token_.decimals();

        __UUPSUpgradeable_init();
        __FluentHostable_init(host_);
    }

    /**************************************************************************
     * Stream functions
     *************************************************************************/
    // function updateMask(
    //     address account,
    //     uint index,
    //     bool active
    // ) external onlyHost {
    //     _masks[account] = _masks[account].setTo(index, active);
    // }

    // function maskOf(address acount) external {

    // }

    // function openStream(address account, uint index) external onlyHost {
    //     // set bitmap slot at index to 1
    // }

    // function closeStream(address account, uint index) external onlyHost {
    //     // set bitmap slot at index to 0
    // }

    // function accountStreams(address account) external {
    //     // call host with local token mask bitmap
    // }

    /**************************************************************************
     * Token wrapper functions
     *************************************************************************/
    function deposit(uint256 value) external {
        address sender = _msgSender();

        if (sender == address(this)) {
            revert ERC20InvalidSender(address(this));
        }

        underlying.safeTransferFrom(sender, address(this), value);
        _mint(sender, value);
    }

    function withdraw(uint256 value) external {
        address recipient = _msgSender();

        _burn(recipient, value);
        underlying.safeTransfer(recipient, value);
    }

    /**************************************************************************
     * Balance functions
     *************************************************************************/
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address account,
        address spender
    ) public view returns (uint256) {
        return _allowances[account][spender];
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
        _transfer(_msgSender(), to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);

        return true;
    }

    /**************************************************************************
     * Token helper functions
     *************************************************************************/
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _balances[account] = _balances[account] + value;
        totalSupply = totalSupply + value;
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        uint256 balance = balanceOf(account);

        if (balance < value) {
            revert ERC20InsufficientBalance(account, balance, value);
        }

        _balances[account] = _balances[account] - value;
        totalSupply = totalSupply - value;
    }

    function _transfer(address from, address to, uint256 amount) internal {
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
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
