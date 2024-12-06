// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentHost} from "../host/IFluentHost.sol";
import {IFluentToken} from "../token/IFluentToken.sol";
import {IFluentCollectorFactory} from "./IFluentCollectorFactory.sol";

interface IFluentProvider {
    function initialize(
        address owner_,
        // address factory_,
        IFluentHost host_
    ) external;

    // function factory() external view returns (address);

    function owner() external view returns (address);
}
