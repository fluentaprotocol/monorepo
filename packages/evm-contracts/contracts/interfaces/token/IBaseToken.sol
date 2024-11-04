// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBaseToken is IERC20, IERC20Errors, IERC20Metadata {
    function underlying() external view returns (address);

    function deposit(uint256 value) external;

    function withdraw(uint256 value) external;
}
