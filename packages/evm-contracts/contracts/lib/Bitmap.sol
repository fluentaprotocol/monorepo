// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import "hardhat/console.sol";

library Bitmap {
    function nextAvailableSlot(uint256 bitmap) internal pure returns (bool, uint) {
        for (uint i = 0; i < 256; i++) {
            if ((bitmap & (1 << i)) == 0) {
                return (true, i);
            }
        }

        return (false, 0);
    }
}
