// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.4;

import {UUPSUtils} from "./UUPSUtils.sol";
import {UUPSProxy} from "./UUPSProxy.sol";
import {IFluentFactory} from "../interfaces/IFluentFactory.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxy
 *
 * NOTE:
 * - Compliant with [Universal Upgradeable Proxy Standard](https://eips.ethereum.org/EIPS/eip-1822)
 * - Compiiant with [Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
 * - Implements delegation of calls to other contracts, with proper forwarding of
 *   return values and bubbling of failures.
 * - It defines a fallback function that delegates all calls to the implementation.
 */
contract FactoryProxy is UUPSProxy {
    bytes32 constant ss = 0x0;

    /// @dev Proxy._implementation implementation
    function _implementation() internal view override returns (address) {
        return
            IFluentFactory(UUPSUtils.implementation()).implementation();
    }
}
