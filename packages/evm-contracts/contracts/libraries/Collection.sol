// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Bucket, BucketUtils} from "./Bucket.sol";

// option
// token
// amount

// -- bucket --
// interval
// freeTrial

struct BucketCollection {
    bytes4[] ids;
    mapping(bytes4 => Bucket) data;
    mapping(bytes4 => uint) indicies;
}

library CollectionUtils {
    using BucketUtils for Bucket;



    function get(
        BucketCollection storage self,
        bytes4 tag
    ) internal view returns (Bucket storage) {
        return self.data[tag];
    }

    function add(
        BucketCollection storage self,
        Bucket calldata data
    ) internal returns (bytes4 id) {
        id = data.id();

        uint index = self.ids.length;

        self.ids.push(id);
        self.data[id] = data;
        self.indicies[id] = index;
    }

    function remove(BucketCollection storage self, bytes4 id) internal {
        uint index = self.indicies[id];
        uint last = self.ids.length - 1;

        self.ids[index] = self.ids[last];
        self.ids.pop();

        delete self.data[id];
        delete self.indicies[id];
    }
}

// Bucket id = keccak256(provider, token, interval);

// bucket id gets following data
// group -> name
// token
// interval
// amount
