// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentProvider} from "./IFluentProvider.sol";
import {IFluentFactory} from "../IFluentFactory.sol";

interface IFluentProviderFactory is IFluentFactory {
    error UnauthorizedCollector(address actor);

    // function implementation() external view returns (IFluentProvider);
    // function whitelisted(address collector) external view returns (bool);

    function openProvider() external returns (address);
    function closeProvider(IFluentProvider provider) external;
}
