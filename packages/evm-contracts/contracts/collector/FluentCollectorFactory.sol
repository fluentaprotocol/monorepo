// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSProxy} from "../upgradeability/UUPSProxy.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Bitmap} from "../lib/Bitmap.sol";

import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";

contract FluentTokenFactory is Context {
    using Bitmap for uint256;

    IFluentCollector public immutable _IMPLEMENTAION;

    mapping(bytes32 => address) private _collectors;
    mapping(address => uint256) private _collectorStates;

    constructor(IFluentCollector implementation) {
        _IMPLEMENTAION = IFluentCollector(implementation);
    }

    function createCollector() external returns (IFluentCollector) {
        uint256 bitmap = _collectorStates[_msgSender()];
        (bool available, uint index) = bitmap.nextAvailableSlot();

        if (!available) {
            revert("all collector slots for this account are taken");
        }

        bytes32 id = collectorId(_msgSender(), index);

        UUPSProxy proxy = new UUPSProxy{salt: id}();
        address proxyAddress = address(proxy);

        proxy.initializeProxy(address(_IMPLEMENTAION));

        IFluentCollector collector =  IFluentCollector(proxyAddress);

        collector.initialize();

        return collector;
    }

    function collectorId(
        address owner,
        uint index
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(owner, index));
    }

    // function createToken(IERC20Metadata underlying) external returns (IFluentToken) {
    //     address underlyingAddress = address(underlying);

    //     require(
    //         _proxies[underlyingAddress] == address(0),
    //         "Token already exists"
    //     );

    //     bytes32 salt = keccak256(abi.encode(underlyingAddress));

    //     UUPSProxy proxy = new UUPSProxy{salt: salt}();
    //     address proxyAddress = address(proxy);

    //     _proxies[underlyingAddress] = proxyAddress;
    //     proxy.initializeProxy(address(_TOKEN_IMPLEMENTAION));

    //     IFluentToken token = IFluentToken(proxyAddress);

    //     string memory name = string.concat("Fluent ", underlying.name());
    //     string memory symbol = string.concat(underlying.symbol(), '.fl');

    //     token.initialize(underlying, name, symbol);

    //     return token;
    // }
}
