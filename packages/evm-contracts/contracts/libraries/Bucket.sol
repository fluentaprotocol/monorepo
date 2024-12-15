// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Interval} from "./Interval.sol";
import {CollectionUtils} from "./Collection.sol";

struct Bucket {
    string name;
    Interval interval;
}

struct BucketCollection {
    bytes4[] tags;
    mapping(bytes4 => Bucket) data;
    mapping(bytes4 => uint) indicies;
}

library BucketUtils {
    function tag(Bucket calldata self) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encode(self.name, self.interval)));
    }

    
    function get(
        BucketCollection storage self,
        bytes4 tag_
    ) internal view returns (Bucket storage) {
        return self.data[tag_];
    }

    function add(
        BucketCollection storage self,
        bytes4 tag_,
        Bucket calldata data
    ) internal returns (bool) {
               bool success = CollectionUtils.add(tag_, self.tags, self.indicies);

        if (success){
            self.data[tag_] = data;
        }

        return success;
    }

    function remove(
        BucketCollection storage self,
        bytes4 tag_
    ) internal returns (bool) {
        bool success = CollectionUtils.remove(tag_, self.tags, self.indicies);

        if (success){
            delete self.data[tag_];
        }

        return success;
    }

    function contains(
        BucketCollection storage self,
        bytes4 tag_
    ) internal view returns (bool) {
        return CollectionUtils.contains(self.indicies, tag_);
    }
}
