// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";

import {IFluentToken} from "../interfaces/token/IFluentToken.sol";

contract FluentTokenFactory {
    IFluentToken public immutable _TOKEN_IMPLEMENTAION;

    mapping(address => address) private _proxies;

    constructor(IFluentToken tokenImplementation) {
        _TOKEN_IMPLEMENTAION = IFluentToken(tokenImplementation);
    }

    function createToken(IERC20Metadata underlying) external returns (IFluentToken) {
        address underlyingAddress = address(underlying);

        require(
            _proxies[underlyingAddress] == address(0),
            "Token already exists"
        );

        bytes32 salt = keccak256(abi.encode(underlyingAddress));

        UUPSProxy proxy = new UUPSProxy{salt: salt}();
        address proxyAddress = address(proxy);

        _proxies[underlyingAddress] = proxyAddress;
        proxy.initializeProxy(address(_TOKEN_IMPLEMENTAION));

        IFluentToken token = IFluentToken(proxyAddress);

        string memory name = string.concat("Fluent ", underlying.name());
        string memory symbol = string.concat(underlying.symbol(), '.fl');

        token.initialize(underlying, name, symbol);

        return token;
    }
}
