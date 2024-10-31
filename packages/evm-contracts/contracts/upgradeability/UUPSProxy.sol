// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IUUPSProxy} from "../interfaces/upgradeability/IUUPSProxy.sol";

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
contract UUPSProxy is IUUPSProxy, Proxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function initializeProxy(address implementation) external {
        require(implementation != address(0), "UUPSProxy: zero address");
        require(
            _implementation() == address(0),
            "UUPSProxy: already initialized"
        );

        _setImplementation(implementation);
    }

    /// @dev Proxy._implementation implementation
    function _implementation()
        internal
        view
        virtual
        override
        returns (address impl)
    {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function _setImplementation(address implementation) internal {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    receive() external payable {
        _delegate(_implementation());
    }
}
