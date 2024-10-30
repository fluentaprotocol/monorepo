// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IBaseToken} from "../interfaces/IBaseToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract BaseToken is IBaseToken, ContextUpgradeable {
    using SafeCast for int256;
    using SafeCast for uint256;

    IERC20Metadata private _underlying;

    string private _symbol;
    string private _name;

    uint256 internal _totalSupply;

    mapping(address => int256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    function __BaseToken_init(
        IERC20Metadata token,
        string calldata name_,
        string calldata symbol_
    ) internal {
        _underlying = token;
        _symbol = symbol_;
        _name = name_;

        __Context_init();
    }

    /**************************************************************************
     * Token meta functions
     *************************************************************************/
    function decimals() public view returns (uint8) {
        return _underlying.decimals();
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function underlying() external view returns (address) {
        return address(_underlying);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**************************************************************************
     * Balance functions
     *************************************************************************/
    function balanceOf(
        address account
    ) public view virtual override(IERC20) returns (uint256) {
        int256 balance = _balances[account];

        return balance < 0 ? 0 : uint256(balance);
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
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
     * Token transfer / approve functions
     *************************************************************************/
    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value.toInt256());
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, value);
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
}
