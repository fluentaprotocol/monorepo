// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

struct Bucket {
    uint256 amount;
    address token;
    uint64 interval;
    uint32 freeTrial;
}

library BucketUtils {
    function id(Bucket calldata self) internal pure returns (bytes4 _id){
        assembly {
            _id := keccak256(self, 0x40)
        }
    } 
}

// Bucket id = keccak256(provider, token, interval);

// bucket id gets following data
// group -> name
// token
// interval
// amount