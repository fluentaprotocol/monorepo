// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentHost} from "../host/IFluentHost.sol";
import {IFluentToken} from "../token/IFluentToken.sol";
import {IFluentProviderFactory} from "./IFluentProviderFactory.sol";

interface IFluentProvider {
    function initialize(
        address owner_,
        address host_
    ) external;

    // function bucketData(
    //     bytes4 bucket
    // ) external view returns (address token, uint64 interval, uint256 amount);

    // function factory() external view returns (address);

    function owner() external view returns (address);
}
