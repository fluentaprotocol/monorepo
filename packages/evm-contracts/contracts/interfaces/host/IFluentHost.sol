// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentCollectorFactory} from "../collector/IFluentCollectorFactory.sol";
import {IFluentToken} from "../token/IFluentToken.sol";
import {IFluentTokenFactory} from "../token/IFluentTokenFactory.sol";

interface IFluentHost {
    error UnauthorizedCollector(address actor);
    // error UnauthorizedCollectorFactory(address actor);

    function tokenFactory() external view returns (IFluentTokenFactory);
    function collectorFactory() external view returns (IFluentCollectorFactory);

    function openStream(address account, IFluentToken token) external returns (bytes32);
    function closeStream(bytes32 stream) external;
}
