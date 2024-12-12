// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IFluentToken} from "./IFluentToken.sol";
import {Bucket} from "../libraries/Bucket.sol";

interface IFluentProvider {
    function getBucket(
        bytes32 provider,
        bytes4 bucket
    ) external view returns (Bucket memory);

    function test(
        bytes32 provider,
        bytes4 bucket
    ) external returns (Bucket memory, address recipient);
}
