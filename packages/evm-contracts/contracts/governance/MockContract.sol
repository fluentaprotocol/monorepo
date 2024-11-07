// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockContract {
    uint256 public value;

    event ValueSet(uint256 newValue);

    function setValue(uint256 newValue) external {
        value = newValue;
        emit ValueSet(newValue);
    }
}
