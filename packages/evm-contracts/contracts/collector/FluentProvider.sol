// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Storage} from "../lib/Storage.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentProvider} from "../interfaces/provider/IFluentProvider.sol";
import {IFluentProviderFactory} from "../interfaces/provider/IFluentProviderFactory.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

enum Interval {
    Daily
}

struct Tier {
    string name;
    uint64 window;
    uint64 interval;
    mapping(address => uint256) _buckets;
}

contract FluentProvider is IFluentProvider, FluentHostable {
    using SafeERC20 for IFluentToken;
    using EnumerableSet for EnumerableSet.Set;

    address public owner;

    function initialize(address owner_, address host_) external override initializer {
        address sender = _msgSender();
        IFluentHost host__ = IFluentHost(host_);

        if (sender != host__.providerFactory()) {
            revert("UnauthorizedFactory");
        }

        owner = owner_;

        __Context_init();
        __FluentHostable_init(host__);
    }

    function bucketData(
        bytes4 bucket
    ) external view returns (address token, uint64 interval, uint256 amount) {}

    function createTier(
        address token,
        uint256 amount
    ) external onlyOwner returns (bytes4) {}

    // function createTier(
    //     uint32 interval,
    //     uint32 window,
    //     string calldata name
    //     // address[] calldata tokens,
    //     // uint256[] calldata amounts
    // ) external onlyOwner {
    //     // if (tokens.length != amounts.length) {
    //     //     revert("InvalidAmounts");
    //     // }

    //     // if (tokens.length == 0) {
    //     //     revert("InvalidTokens");
    //     // }

    //     // generate the tier id
    //     // create multiple buckets with reference back to the tier
    // }

    // function createBucket(
    //     IFluentToken token,

    //     uint32 interval,
    //     uint256 amount
    // ) external onlyOwner {}

    // function deleteBucket() external onlyOwner {}

    // function _authorizeUpgrade(address newImplementation) internal override {}

    modifier onlyOwner() {
        address sender = _msgSender();

        if (sender != owner) {
            revert("UnauthorizedOwner");
        }

        _;
    }
}
