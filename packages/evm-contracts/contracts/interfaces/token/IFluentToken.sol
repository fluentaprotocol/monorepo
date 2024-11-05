// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentHost} from "../host/IFluentHost.sol";
import {IFluentHostable} from "../host/IFluentHostable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFluentToken is
    IERC20,
    IERC20Errors,
    IERC20Metadata,
    IFluentHostable
{
    // function initialize(
    //     IFluentHost host_,
    //     IERC20Metadata token_,
    //     string calldata name_,
    //     string calldata symbol_
    // ) external;
}
