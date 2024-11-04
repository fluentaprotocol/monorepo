// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";
import {FluentHostable} from "../host/FluentHostable.sol";
import {BaseToken} from "./BaseToken.sol";

import "hardhat/console.sol";

contract FluentToken is BaseToken, FluentHostable {
    using SafeCast for uint256;
    using SafeCast for int256;

    mapping(address => uint256) private _masks;

    function initialize(
        IFluentHost host_,
        IERC20Metadata token_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __UUPSUpgradeable_init();
        __FluentHostable_init(host_);
        __BaseToken_init(token_, name_, symbol_);
    }

    function openStream(address account, uint index) external onlyHost {
        // set bitmap slot at index to 1
    }

    function closeStream(address account, uint index) external onlyHost {
        // set bitmap slot at index to 0
    }

    function accountStreams(address account) external {
        // call host with local token mask bitmap
    }

    function accountSolvent(address account) external pure returns (bool) {
        return account != address(0);
    }

    function accountCritical(address account) external pure returns (bool) {
        return account != address(0);
    }

    /**************************************************************************
     * UUPS Upgrade implementation
     *************************************************************************/
    function _authorizeUpgrade(address newImplementation) internal override {}
}
