// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Bitmap} from "../lib/Bitmap.sol";
import {Account} from "../lib/Account.sol";
import {Storage} from "../lib/Storage.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {FluentToken} from "../token/FluentToken.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {IFluentTokenFactory} from "../interfaces/token/IFluentTokenFactory.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FluentTokenFactory is IFluentTokenFactory, FluentHostable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IFluentToken public implementation;

    EnumerableSet.AddressSet private _tokens;
    mapping(address => address) private _wrapped;

    function initialize(
        IFluentHost host,
        IFluentToken implemenation_
    ) external initializer onlyProxy {
        implementation = implemenation_;

        __UUPSUpgradeable_init();
        __FluentHostable_init(host);
    }

    /**************************************************************************
     * Core functions
     *************************************************************************/
    function createToken(
        IERC20Metadata underlying
    ) external onlyProxy returns (IFluentToken) {
        address underlyingAddress = address(underlying);

        require(
            address(_wrapped[underlyingAddress]) == address(0),
            "Token already exists"
        );

        bytes32 salt = keccak256(abi.encode(underlyingAddress));

        UUPSProxy proxy = new UUPSProxy{salt: salt}();

        address proxyAddress = address(proxy);
        FluentToken token = FluentToken(proxyAddress);

        proxy.initializeProxy(address(implementation));

        string memory name = string.concat("Fluent ", underlying.name());
        string memory symbol = string.concat(underlying.symbol(), ".fl");

        token.initialize(host, underlying, name, symbol);

        _tokens.add(proxyAddress);
        _wrapped[underlyingAddress] = proxyAddress;

        return token;
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
