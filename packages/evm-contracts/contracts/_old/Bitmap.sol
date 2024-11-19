// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import "hardhat/console.sol";

struct bitmap {
    
    uint256 map;
}

library Bitmap {
    uint internal constant MAX_INDEX = 256; 

    error IndexOutOfRange();

    function get(
        bitmap storage bitmap_,
        uint256 index
    ) internal view returns (bool) {
        _validateIndex(index);

        return (bitmap_.map & (1 << index)) != 0;
    }

    function allSet(
        bitmap storage bitmap_
    ) internal view returns (uint[] memory result) {
        result = new uint[](MAX_INDEX);

        uint n = 0;
        uint map = bitmap_.map;

        for (uint i = 0; i < MAX_INDEX; i++) {
            if ((map & (1 << i)) != 0) {
                result[n++] = i;
            }
        }

        assembly {
            mstore(result, n)
        }
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(bitmap storage bitmap_, uint256 index, bool value) internal {
        _validateIndex(index);

        if (value) {
            bitmap_.map |= (1 << index);
        } else {
            bitmap_.map &= ~(1 << index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(bitmap storage bitmap_, uint256 index) internal {
        setTo(bitmap_, index, true);
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(bitmap storage bitmap_, uint256 index) internal {
        setTo(bitmap_, index, false);
    }

    function nextUnset(
        bitmap storage bitmap_
    ) internal view returns (bool, uint) {
        uint map = bitmap_.map;

        for (uint i = 0; i < MAX_INDEX; i++) {
            if (map & (1 << i) == 0) {
                return (true, i);
            }
        }

        return (false, 0);
    }


    function _validateIndex(uint index) private pure {
        if (index >= MAX_INDEX) {
            revert IndexOutOfRange();
        }
    }
}
