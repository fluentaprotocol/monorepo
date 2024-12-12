// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IFluentToken} from "../interfaces/IFluentToken.sol";

// option
// token
// amount

// -- bucket --
// interval
// freeTrial

struct Bucket {
    uint256 amount;
    address token;
    uint64 interval;
}

library BucketUtils {
    function id(Bucket calldata self) internal pure returns (bytes4 _id) {
        assembly {
            _id := keccak256(self, 0x40)
        }
    }

    function exists(Bucket storage self) internal view returns (bool) {
        return self.amount != 0 && self.token != address(0) && self.interval == 0;
    }

    // function from
}

// Bucket id = keccak256(provider, token, interval);

// bucket id gets following data
// group -> name
// token
// interval
// amount
