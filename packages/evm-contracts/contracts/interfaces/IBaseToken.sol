// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBaseToken is IERC20Errors, IERC20, IERC20Metadata {
    function initialize(
        IERC20Metadata token,
        string calldata name_,
        string calldata symbol_
    ) external;
}