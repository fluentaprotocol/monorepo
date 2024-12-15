// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Endpoint, EndpointUtils} from "./Bucket.sol";

struct EndpointCollection {
    bytes4[] tags;
    mapping(bytes4 => Endpoint) data;
    mapping(bytes4 => uint) indicies;
}

library CollectionUtils {
    using EndpointUtils for Endpoint;

    function get(
        EndpointCollection storage self,
        bytes4 tag
    ) internal view returns (Endpoint storage) {
        return self.data[tag];
    }

    function add(
        EndpointCollection storage self,
        bytes4 tag,
        Endpoint calldata data
    ) internal returns (bool) {
        if (!contains(self, tag)) {
            self.tags.push(tag);

            self.indicies[tag] = self.tags.length;
            self.data[tag] = data;

            return true;
        } else {
            return false;
        }
    }

    function remove(
        EndpointCollection storage self,
        bytes4 tag
    ) internal returns (bool) {
        uint256 index = self.indicies[tag];

        if (index != 0) {
            uint256 tagIndex = index - 1;
            uint256 lastIndex = self.tags.length - 1;

            if (tagIndex != lastIndex) {
                bytes4 lastValue = self.tags[lastIndex];

                // Move the lastValue to the index where the value to delete is
                self.tags[tagIndex] = lastValue;
                self.indicies[lastValue] = index;
            }

            // Delete the slot where the moved value was stored
            self.tags.pop();

            // Delete the tracked position for the deleted slot
            delete self.indicies[tag];
            delete self.data[tag];

            return true;
        } else {
            return false;
        }
    }

    function contains(
        EndpointCollection storage self,
        bytes4 tag
    ) internal view returns (bool) {
        return self.indicies[tag] != 0;
    }

    function clear(EndpointCollection storage self) internal {}
}
