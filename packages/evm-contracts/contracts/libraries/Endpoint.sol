// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Interval} from "./Interval.sol";
import {CollectionUtils} from "./Collection.sol";

struct Endpoint {
    uint256 amount;
    address token;
    bytes4 bucket;
}

struct EndpointCollection {
    bytes4[] tags;
    mapping(bytes4 => Endpoint) data;
    mapping(bytes4 => uint) indicies;
}

library EndpointUtils {
    function tag(Endpoint calldata self) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encode(self.token, self.bucket)));
    }

    function get(
        EndpointCollection storage self,
        bytes4 tag_
    ) internal view returns (Endpoint storage) {
        return self.data[tag_];
    }

    function add(
        EndpointCollection storage self,
        bytes4 tag_,
        Endpoint calldata data
    ) internal returns (bool) {
               bool success = CollectionUtils.add(tag_, self.tags, self.indicies);

        if (success){
            self.data[tag_] = data;
        }

        return success;
    }

    function remove(
        EndpointCollection storage self,
        bytes4 tag_
    ) internal returns (bool) {
        bool success = CollectionUtils.remove(tag_, self.tags, self.indicies);

        if (success){
            delete self.data[tag_];
        }

        return success;
    }

    function contains(
        EndpointCollection storage self,
        bytes4 tag_
    ) internal view returns (bool) {
        return CollectionUtils.contains(self.indicies, tag_);
    }
}
