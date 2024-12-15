// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {Endpoint, EndpointUtils} from "./Endpoint.sol";
import {EndpointCollection, CollectionUtils} from "./Collection.sol";

struct Provider {
    bytes32 id;
    string name;
    address owner;
}

library ProviderUtils {

    function id(
        string calldata name,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, name));
    }

    function open(
        Provider storage self,
        address owner,
        string calldata name
        // BucketParams[] calldata buckets
    ) internal {
        // Update provider details
        self.id = id(name, owner);
        self.name = name;
        self.owner = owner;

        // // Cache length for efficiency and iterate buckets
        // uint len = buckets.length;
        // for (uint i; i < len; ) {
        //     // addEndpoint(self, buckets[i]);

        //     unchecked {
        //         ++i;
        //     }
        // }
    }

    function close(Provider storage self) internal {
        delete self.owner;
        delete self.name;
        delete self.id;
    }

    function exists(Provider storage self) internal view returns (bool) {
        return self.owner != address(0);
    }

    // function hasBucket(
    //     Provider storage self,
    //     bytes4 tag
    // ) internal view returns (bool) {
    //     return self.buckets.contains(tag);
    // }

    // function getEndpoint(
    //     Provider storage self,
    //     bytes4 tag
    // ) internal view returns (Endpoint storage) {
    //     if (!self.endpoints.contains(tag)) {
    //         revert EndpointDoesNotExist();
    //     }

    //     return self.endpoints.get(tag);
    // }

    // function addEndpoint(
    //     Provider storage self,
    //     Endpoint calldata data
    // ) internal returns (bytes4) {
    //     bytes4 tag = data.tag();

    //     if (self.endpoints.contains(tag)) {
    //         revert EndpointAlreadyExists();
    //     }

    //     self.endpoints.add(tag, data);

    //     // emit BucketCreated(self.id, tag);

    //     return tag;
    // }

    // function removeEndpoint(Provider storage self, bytes4 tag) internal {
    //     if (!self.endpoints.contains(tag)) {
    //         revert EndpointDoesNotExist();
    //     }

    //     self.endpoints.remove(tag);
    // }

    // function modifyEndpoint(
    //     Provider storage self,
    //     bytes4 tag,
    //     uint256 amount
    // ) internal {
    //     Endpoint storage bucket = getEndpoint(self, tag);

    //     bucket.amount = amount;
    // }
}
