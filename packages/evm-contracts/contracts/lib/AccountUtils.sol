// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {StorageUtils} from "./StorageUtils.sol";

library AccountUtils {
    string private constant USER_NAMESPACE = "fluenta.user";

    function account(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(USER_NAMESPACE, user));
    }
}
