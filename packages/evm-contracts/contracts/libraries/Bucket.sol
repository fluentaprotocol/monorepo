// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";
import {Interval} from "./Interval.sol";

struct BucketParams {
    string name;
    Interval interval;
    EndpointParams[] endpoints;
}

struct Bucket {
    string name;
    Interval interval;
}

struct EndpointParams {
    uint256 amount;
    address token;
}

struct Endpoint {
    uint256 amount;
    address token;
    Interval interval;
    bytes4 bucket;
}

library EndpointUtils {
    function tag(Endpoint calldata self) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encode(self.token, self.bucket)));

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
