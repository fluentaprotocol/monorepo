// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import "hardhat/console.sol";

struct Bitmap {
    uint map;
}

library BitmapUtils {
    uint internal constant MAX_INDEX = 256;

    error IndexOutOfRange();

    function get(
        Bitmap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        _validateIndex(index);

        return bitmap.map & _mask(index) != 0;
    }

    function allSet(
        Bitmap storage bitmap
    ) internal view returns (uint[] memory result) {
        result = new uint[](MAX_INDEX);

        uint i = 0;
        uint n = 0;
        uint map = bitmap.map;

        while (i < MAX_INDEX) {
            if (map & _mask(i) != 0) {
                result[n++] = i;
            }

            unchecked {
                i++;
            }
        }

        assembly {
            mstore(result, n)
        }
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(Bitmap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(Bitmap storage bitmap, uint256 index) internal {
        _validateIndex(index);

        bitmap.map |= (1 << (index & 0xff));
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(Bitmap storage bitmap, uint256 index) internal {
        _validateIndex(index);

        bitmap.map &= ~_mask(index);
    }

    function nextUnset(Bitmap storage bitmap) internal view returns (bool, uint) {
        uint map = bitmap.map;
        
        for (uint i = 0; i < MAX_INDEX; i++) {
            if (map & _mask(i) == 0) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function _mask(uint index) private pure returns (uint256) {
        return 1 << (index & 0xff);
    }

    function _validateIndex(uint index) private pure {
        if (index >= MAX_INDEX) {
            revert IndexOutOfRange();
        }
    }
}
