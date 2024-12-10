// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DateTime} from "../libraries/DateTime.sol";

contract MockDateTime {
    function datestamp(
        uint year,
        uint month,
        uint day
    ) external pure returns (uint) {
        return DateTime.timestamp(year, month, day);
    }

    function timestamp(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) external pure returns (uint) {
        return DateTime.timestamp(year, month, day, hour, minute, second);
    }

    function date(
        uint timestamp_
    ) external pure returns (uint year, uint month, uint day) {
        return DateTime.date(timestamp_);
    }

    function addMonth(uint timestamp_) external pure returns (uint64) {
        return uint64(DateTime.addMonths(timestamp_, 1));
    }

    function datetime(
        uint timestamp_
    )
        external
        pure
        returns (
            uint year,
            uint month,
            uint day,
            uint hour,
            uint minute,
            uint second
        )
    {
        return DateTime.datetime(timestamp_);
    }
}
