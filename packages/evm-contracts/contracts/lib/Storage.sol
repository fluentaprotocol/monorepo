// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

library Storage {
    function store(bytes32 slot, bytes32[] memory data) internal  {
        for (uint i = 0; i < data.length; ++i) {
            bytes32 d = data[i];

            assembly {
                sstore(add(slot, i), d)
            }
        }
    }

    function load(
        bytes32 slot,
        uint dataLength
    ) internal view returns (bytes32[] memory data) {
        data = new bytes32[](dataLength);
        for (uint j = 0; j < dataLength; ++j) {
            bytes32 d;
            assembly {
                d := sload(add(slot, j))
            }
            data[j] = d;
        }
    }

    function clear(bytes32 slot, uint dataLength) internal {
        for (uint j = 0; j < dataLength; ++j) {
            assembly {
                sstore(add(slot, j), 0)
            }
        }
    }

    // function empty(bytes32 slot, uint dataLength) internal view returns (bool) {
    //     for (uint j = 0; j < dataLength; ++j) {
    //         bytes32 d;

    //         assembly {
    //             d := sload(add(slot, j))
    //         }

    //         if (uint256(d) > 0) return false;
    //     }

    //     return true;
    // }
}
