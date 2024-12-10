// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ProviderKey} from "./ProviderKey.sol";

type ProviderId is bytes32;

struct Channel {
    bytes32 provider;
    address account;
    uint64 expired;
    bytes4 bucket;
}

struct Bucket {
    bytes32 name;
    uint64 trial;
    uint64 interval;

    mapping(address => uint256) tokens;
}

struct Provider {
    string name;
    address owner;

    mapping(bytes4 bucket => Bucket data) buckets;
}

library ProviderLib {
    function openProvider(string calldata name) internal {

    }
    
    function closeProvider(bytes32 provider) internal {

    }

    function transferProvider(bytes32 provider, address ) internal {

    }
}

/// @notice Library for computing the ID of a pool
library ProviderIdLibrary {
    /// @notice Returns value equal to keccak256(abi.encode(poolKey))
    function toId(
        ProviderKey memory providerKey
    ) internal pure returns (ProviderId poolId) {
        assembly ("memory-safe") {
            // 0xa0 represents the total size of the poolKey struct (5 slots of 32 bytes)
            poolId := keccak256(providerKey, 0xa0)
        }
    }
}
