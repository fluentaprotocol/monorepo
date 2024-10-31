// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

interface IUUPSProxy {
    function initializeProxy(address implementation) external;

}
