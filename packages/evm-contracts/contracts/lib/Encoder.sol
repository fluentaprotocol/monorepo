// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "hardhat/console.sol";

library Encoder {
    using SafeCast for uint256;
    using SafeCast for int256;

    function encodeInt256(int256 value) internal pure returns (bytes32 data){
        assembly {
            data := value
        }
    }    
    
    function decodeInt256(bytes32 data) internal pure returns (int256 value){
        assembly {
            value := mload(add(data, 0x20))
        }
    }    
}
