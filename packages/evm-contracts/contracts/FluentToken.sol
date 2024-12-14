// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20WrapperUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentProvider} from "./interfaces/IFluentProvider.sol";
import {IFluentHost} from "./interfaces/IFluentHost.sol";
import {IFluentToken} from "./interfaces/IFluentToken.sol";
import {FluentHostable} from "./FluentHostable.sol";

import "hardhat/console.sol";

contract FluentToken is
    ERC20WrapperUpgradeable,
    FluentHostable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    // IERC20Metadata public underlying;

    function initialize(
        IFluentHost host_,
        IERC20Metadata token_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __Context_init();
        __UUPSUpgradeable_init();
        __ERC20Wrapper_init(token_);
        __ERC20_init(name_, symbol_);
        __FluentRoutable_init(host_);
    }

    /**
     * @dev Allow the host to process transactions
     */
    function transact(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) external onlyRouter {
        _update(from, to, value - fee);
        _burn(from, fee);
    }

    function transactFor(
        address behalf,
        address from,
        address to,
        uint256 value,
        uint256 reward,
        uint256 fee
    ) external onlyRouter {
        _update(from, behalf, reward);
        _update(from, to, value);

        _burn(from, fee);
    }

    function totalFeed() external view returns (uint256) {
        uint totalSupply = underlying().totalSupply();
        uint balance = underlying().balanceOf(address(this));

        return balance - totalSupply;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
