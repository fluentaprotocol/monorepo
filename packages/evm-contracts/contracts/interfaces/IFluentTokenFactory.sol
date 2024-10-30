// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IFluentToken} from "../interfaces/IFluentToken.sol";

interface IFluentTokenFactory {
    function createToken(
        IERC20Metadata underlying
    ) external returns (IFluentToken);
}
