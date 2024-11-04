// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentHost} from "../host/IFluentHost.sol";
import {IFluentCollectorFactory} from "./IFluentCollectorFactory.sol";
import {IFluentHostErrors} from '../IFluentHostErrors.sol';

interface IFluentCollector is IFluentHostErrors {
    error UnauthorizedFactory(address actor);

    function initialize(
        IFluentHost host,
        bytes32 slot
    ) external;


    function slot() external view returns (bytes32);

    function factory() external view returns (IFluentCollectorFactory);

    function terminate() external;
}
