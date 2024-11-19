// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IFluentCollector} from "../interfaces/collector/IFluentCollector.sol";
import {IFluentCollectorFactory} from "../interfaces/collector/IFluentCollectorFactory.sol";
import {IFluentToken} from "../interfaces/token/IFluentToken.sol";
import {IFluentTokenFactory} from "../interfaces/token/IFluentTokenFactory.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFluentHost} from "../interfaces/host/IFluentHost.sol";

import "hardhat/console.sol";

contract FluentHost is IFluentHost, UUPSUpgradeable, ContextUpgradeable {
    IFluentTokenFactory public tokenFactory;
    IFluentCollectorFactory public collectorFactory;

    mapping(bytes32 stream => address collector) private _streams;

    function initialize(address _tokenFactory) external initializer {
        tokenFactory = IFluentTokenFactory(_tokenFactory);

        __Context_init();
        __UUPSUpgradeable_init();
    }

    function registerStream(
        bytes32 stream,
        IFluentToken token
    ) external onlyCollector {
        address account = address(0);
        address collector = _msgSender();

        // token.depositBuffer(account, 1e6);
        token.performTransaction();

        _streams[stream] = collector;
    }

    function deleteStream(
        bytes32 stream,
        IFluentToken token
    ) external onlyCollector {
        address collector = _msgSender();
        address account = address(0);

        if (collector != _streams[stream]) {
            revert("UnauthorizedCollector");
        }

        // token.transferBuffer(account, 1e6);
        token.performTransaction();

        delete _streams[stream];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyDAO {}

    modifier onlyDAO() {
        _;
    }

    modifier onlyCollector() {
        _;
    }
}
