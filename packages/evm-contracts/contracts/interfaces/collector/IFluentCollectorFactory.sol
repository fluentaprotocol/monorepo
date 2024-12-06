// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentProvider} from "./IFluentCollector.sol";

interface IFluentCollectorFactory {
    error UnauthorizedCollector(address actor);

    function implementation() external view returns (IFluentProvider);

    // function whitelisted(address collector) external view returns (bool);

    function openCollector() external;

    function closeCollector(IFluentProvider collector) external;
}
