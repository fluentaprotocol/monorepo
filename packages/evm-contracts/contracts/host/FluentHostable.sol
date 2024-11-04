// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentHostable} from "../interfaces/host/IFluentHostable.sol";

abstract contract FluentHostable is IFluentHostable, ContextUpgradeable {
    IFluentHost public host;

    error UnauthorizedHost();

    function __FluentHostable_init(
        IFluentHost host_
    ) internal onlyInitializing {
        host = host_;

        __Context_init();
    }

    modifier onlyHost() {
        if (_msgSender() != address(host)) {
            revert UnauthorizedHost();
        }

        _;
    }
}
