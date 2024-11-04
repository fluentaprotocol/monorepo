// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentCollector} from "./IFluentCollector.sol";

interface IFluentCollectorFactory {
    error UnauthorizedCollector(address actor);

    function implementation() external view returns (address);

    function isCollector(address collector) external view returns (bool);

    function openCollector() external;

    function closeCollector(IFluentCollector collector) external;
}
