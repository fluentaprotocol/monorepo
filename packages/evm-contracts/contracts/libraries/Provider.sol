// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {Bucket, BucketUtils} from "./Bucket.sol";

struct Provider {
    string name;
    address owner;
    mapping(bytes4 => Bucket) buckets;
}

library ProviderUtils {
    using BucketUtils for Bucket;

    event BucketCreated(bytes32 indexed provider, bytes4 bucket);

    function id(
        string calldata name,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, name));
    }

    function open(
        Provider storage self,
        address owner,
        string calldata name,
        Bucket[] calldata buckets
    ) internal {
        bytes32 provider_ = id(name, owner);

        // Update provider details
        self.name = name;
        self.owner = owner;

        // Cache length for efficiency and iterate buckets
        uint len = buckets.length;
        for (uint i; i < len; ) {
            bytes4 bucket_ = buckets[i].id();
            self.buckets[bucket_] = buckets[i];

            emit BucketCreated(provider_, bucket_);

            unchecked {
                ++i;
            }
        }
    }

    function close(Provider storage self) internal {
        delete self.owner;
        delete self.name;
        // delete self.buckets;
    }

    function exists(Provider storage self) internal view returns (bool) {
        return self.owner != address(0);
    }

    function addBucket(Provider storage self, Bucket calldata) internal {}

    function removeBucket(Provider storage self, bytes4 bucket) internal {}

    function modifyBucket(Provider storage self, bytes4 bucket) internal {}
}
