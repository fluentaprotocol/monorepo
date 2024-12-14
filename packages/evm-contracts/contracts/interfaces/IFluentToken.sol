// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFluentToken is IERC20Metadata, IERC20Errors {
    function transact(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) external;

    function transactFor(
        address behalf,
        address from,
        address to,
        uint256 value,
        uint256 reward,
        uint256 fee
    ) external;
}