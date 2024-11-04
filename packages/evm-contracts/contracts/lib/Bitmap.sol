// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import "hardhat/console.sol";

library Bitmap {
    uint internal constant MAX_INDEX = 256;

    error IndexOutOfRange();

    function get(uint256 bitmap, uint256 index) internal pure returns (bool) {
        _validateIndex(index);

        return bitmap & _mask(index) != 0;
    }

    function allSet(
        uint256 bitmap
    ) internal pure returns (uint[] memory result) {
        result = new uint[](MAX_INDEX);

        uint i = 0;
        uint n = 0;

        while (i < MAX_INDEX) {
            if (bitmap & _mask(i) != 0) {
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
    function setTo(
        uint256 bitmap,
        uint256 index,
        bool value
    ) internal pure returns (uint256) {
        _validateIndex(index);

        if (value) {
            return set(bitmap, index);
        } else {
            return unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(
        uint256 bitmap,
        uint256 index
    ) internal pure returns (uint256) {
        _validateIndex(index);

        return bitmap | (1 << (index & 0xff));
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(
        uint256 bitmap,
        uint256 index
    ) internal pure returns (uint256) {
        _validateIndex(index);

        return bitmap & ~_mask(index);
    }

    function nextUnset(uint256 bitmap) internal pure returns (bool, uint) {
        for (uint i = 0; i < MAX_INDEX; i++) {
            if (bitmap & _mask(i) == 0) {
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
