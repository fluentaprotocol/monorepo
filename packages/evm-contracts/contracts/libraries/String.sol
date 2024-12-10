// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library String {
    function length(string storage self) internal view {}

    function length(
        string memory self
    ) internal pure returns (uint256 length_) {
        assembly {
            // Load the first 32 bytes of the string (contains the length)
            length_ := mload(self)
        }
    }
}
