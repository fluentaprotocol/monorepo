// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {DateTimeUtils} from "./DateTime.sol";

enum Interval {
    Daily,
    Weekly,
    Monthly,
    Quaterly,
    Annually
}

library IntervalUtils {
    using DateTimeUtils for *;

    error IntervalNotImplemented(Interval interval);

    function next(
        Interval interval,
        uint timestamp
    ) internal pure returns (uint64) {
        if (interval == Interval.Daily) {
            return uint64(timestamp.addDays(1));
            // DAILY
        } else if (interval == Interval.Weekly) {
            return uint64(timestamp.addWeeks(1));
            // WEEKLY
        } else if (interval == Interval.Monthly) {
            // MONTHLY
            return uint64(timestamp.addMonths(1));
        } else if (interval == Interval.Quaterly) {
            // ANNUALLY
            return uint64(timestamp.addMonths(3));
        } else if (interval == Interval.Annually) {
            // ANNUALLY
            return uint64(timestamp.addYears(1));
        }

        revert IntervalNotImplemented(interval);
    }
}
