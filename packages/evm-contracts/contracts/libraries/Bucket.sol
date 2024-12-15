// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Interval} from "./Interval.sol";

struct Group {
    string name;
    Interval interval;
}

struct Bucket {
    uint256 amount;
    address token;
    bytes4 group;
    Interval interval;
}

library BucketUtils {
    function tag(Bucket calldata self) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encode(self.token, self.group)));

        // assembly {
        //     _id := keccak256(self, 0x40)
        // }
    }

    // function exists(Bucket storage self) internal view returns (bool) {
    //     return self.amount != 0 && self.token != address(0);
    // }

    // function from
}

// Bucket id = keccak256(provider, token, interval);

// bucket id gets following data
// group -> name
// token
// interval
// amount
