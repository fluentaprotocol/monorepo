// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {EndpointCollection, Endpoint} from "./Endpoint.sol";
import {BucketCollection, Bucket} from "./Bucket.sol";

library CollectionUtils {
    
    function contains(
        BucketCollection storage self,
        bytes4 tag
    ) internal view returns (bool) {
        return contains(self.indicies, tag);
    }

    function add(
        bytes4 tag,
        bytes4[] storage tags,
        mapping(bytes4 => uint) storage indicies
    ) internal returns (bool) {
        if (!contains(indicies, tag)) {
            tags.push(tag);

            indicies[tag] = tags.length;
            // self.data[tag] = data;

            return true;
        } else {
            return false;
        }
    }

    function remove(
        bytes4 tag,
        bytes4[] storage tags,
        mapping(bytes4 => uint) storage indicies
    ) internal returns (bool) {
        uint256 index = indicies[tag];

        if (index != 0) {
            uint256 tagIndex = index - 1;
            uint256 lastIndex = tags.length - 1;

            if (tagIndex != lastIndex) {
                bytes4 lastValue = tags[lastIndex];

                // Move the lastValue to the index where the value to delete is
                tags[tagIndex] = lastValue;
                indicies[lastValue] = index;
            }

            // Delete the slot where the moved value was stored
            tags.pop();

            // Delete the tracked position for the deleted slot
            delete indicies[tag];
            // delete self.data[tag];

            return true;
        } else {
            return false;
        }
    }

    function contains(
        mapping(bytes4 => uint) storage indicies,
        bytes4 tag
    ) internal view returns (bool) {
        return indicies[tag] != 0;
    }
}
