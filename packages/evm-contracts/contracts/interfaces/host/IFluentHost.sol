// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentCollectorFactory} from "../collector/IFluentCollectorFactory.sol";

interface IFluentHost {
    error UnauthorizedCollector(address actor);
    error UnauthorizedFactory(address actor);

    function collectorFactory() external view returns (IFluentCollectorFactory);

    function openStream(address account) external returns (bytes32);

    function closeStream(address account) external;
}
