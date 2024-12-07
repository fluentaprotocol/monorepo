// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFluentFactory {
    // function registerStream(bytes32 stream, IFluentToken token) external;
    // function deleteStream(bytes32 stream, IFluentToken token) external;
    // function tokenFactory() external view returns (IFluentTokenFactory);
    function implementation() external view returns (address);
}
