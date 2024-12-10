// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IFluentHost} from "./interfaces/IFluentHost.sol";

abstract contract FluentHostable is ContextUpgradeable {
    IFluentHost public host;

    error UnauthorizedRouter();

    function __FluentRoutable_init(
        IFluentHost host_
    ) internal onlyInitializing {
        host = host_;

        __Context_init();
    }

    modifier onlyRouter() {
        if (_msgSender() != address(host)) {
            revert UnauthorizedRouter();
        }

        _;
    }
}
