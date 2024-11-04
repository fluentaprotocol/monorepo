// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentCollectorFactory} from "../collector/IFluentCollectorFactory.sol";

interface IFluentHost {
    error UnauthorizedCollector(address actor);
    error UnauthorizedFactory(address actor);

    function factory() external view returns (IFluentCollectorFactory);

    function openStream(address account) external;

    function closeStream(address account) external;
}
