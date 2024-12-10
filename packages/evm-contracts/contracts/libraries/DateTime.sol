// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint constant DAY = 24 * 60 * 60;
    uint constant HOUR = 60 * 60;
    uint constant MINUTE = 60;

    int private constant EPOCH_OFFSET = 2440588;
    int private constant JULIAN_OFFSET = 32075;

    function timestamp(
        uint year,
        uint month,
        uint day
    ) internal pure returns (uint) {
        return _daysFromDate(year, month, day) * DAY;
    }

    function timestamp(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) internal pure returns (uint) {
        return
            _daysFromDate(year, month, day) *
            DAY +
            hour *
            HOUR +
            minute *
            MINUTE +
            second;
    }

    function date(
        uint timestamp_
    ) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp_ / DAY);
    }

    function datetime(
        uint timestamp_
    )
        internal
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
        (year, month, day) = _daysToDate(timestamp_ / DAY);

        uint secs = timestamp_ % DAY;

        hour = secs / HOUR;
        secs = secs % HOUR;
        minute = secs / MINUTE;
        second = secs % MINUTE;
    }

    function leapYear(uint64 timestamp_) internal pure returns (bool) {
        (uint year, , ) = _daysToDate(timestamp_ / DAY);
        return leapYear(year);
    }

    function leapYear(uint year) internal pure returns (bool) {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function monthDays(
        uint year,
        uint month
    ) private pure returns (uint daysInMonth) {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = leapYear(year) ? 29 : 28;
        }
    }

    function addYears(
        uint timestamp_,
        uint years_
    ) internal pure returns (uint) {
        (uint year, uint month, uint day) = _daysToDate(timestamp_ / DAY);

        year += years_;

        uint daysInMonth = monthDays(year, month);

        if (day > daysInMonth) {
            day = daysInMonth;
        }

        return _daysFromDate(year, month, day) * DAY + (timestamp_ % DAY);
    }

    function addMonths(
        uint timestamp_,
        uint months_
    ) internal pure returns (uint) {
        (uint year, uint month, uint day) = _daysToDate(timestamp_ / DAY);

        month += months_;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;

        uint daysInMonth = monthDays(year, month);

        if (day > daysInMonth) {
            day = daysInMonth;
        }

        return _daysFromDate(year, month, day) * DAY + (timestamp_ % DAY);
    }

    function addDays(uint timestamp_, uint days_) internal pure returns (uint) {
        return timestamp_ + days_ * DAY;
    }

    function addHours(
        uint timestamp_,
        uint hours_
    ) internal pure returns (uint) {
        return timestamp_ + (hours_ * HOUR);
    }

    function addMinutes(
        uint timestamp_,
        uint minutes_
    ) internal pure returns (uint) {
        return timestamp_ + (minutes_ * MINUTE);
    }

    function addSeconds(
        uint timestamp_,
        uint seconds_
    ) internal pure returns (uint) {
        return timestamp_ + seconds_;
    }

    function _daysFromDate(
        uint year,
        uint month,
        uint day
    ) private pure returns (uint _days) {
        require(year >= 1970, "Year must be 1970 or later");

        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        // Calculate the number of days using integer arithmetic
        int __days = _day -
            JULIAN_OFFSET +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            EPOCH_OFFSET;

        _days = uint(__days);
    }

    function _daysToDate(
        uint _days
    ) private pure returns (uint year, uint month, uint day) {
        int julian = int(_days) + 68569 + EPOCH_OFFSET;
        int century = (4 * julian) / 146097;

        julian = julian - (146097 * century + 3) / 4;

        int _year = (4000 * (julian + 1)) / 1461001;

        julian = julian - (1461 * _year) / 4 + 31;

        int _month = (80 * julian) / 2447;
        int _day = julian - (2447 * _month) / 80;

        julian = _month / 11;

        _month = _month + 2 - 12 * julian;
        _year = 100 * (century - 49) + _year + julian;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    // function subYears(
    //     uint timestamp,
    //     uint _years
    // ) internal pure returns (uint newTimestamp) {
    //     (uint year, uint month, uint day) = _daysToDate(
    //         timestamp / SECONDS_PER_DAY
    //     );
    //     year -= _years;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp =
    //         _daysFromDate(year, month, day) *
    //         SECONDS_PER_DAY +
    //         (timestamp % SECONDS_PER_DAY);
    //     require(newTimestamp <= timestamp);
    // }

    // function subMonths(
    //     uint timestamp,
    //     uint _months
    // ) internal pure returns (uint newTimestamp) {
    //     (uint year, uint month, uint day) = _daysToDate(
    //         timestamp / SECONDS_PER_DAY
    //     );
    //     uint yearMonth = year * 12 + (month - 1) - _months;
    //     year = yearMonth / 12;
    //     month = (yearMonth % 12) + 1;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp =
    //         _daysFromDate(year, month, day) *
    //         SECONDS_PER_DAY +
    //         (timestamp % SECONDS_PER_DAY);
    //     require(newTimestamp <= timestamp);
    // }

    // function subDays(
    //     uint timestamp,
    //     uint _days
    // ) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }

    // function subHours(
    //     uint timestamp,
    //     uint _hours
    // ) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    //     require(newTimestamp <= timestamp);
    // }

    // function subMinutes(
    //     uint timestamp,
    //     uint _minutes
    // ) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    //     require(newTimestamp <= timestamp);
    // }

    // function subSeconds(
    //     uint timestamp,
    //     uint _seconds
    // ) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _seconds;
    //     require(newTimestamp <= timestamp);
    // }

    // function diffYears(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _years) {
    //     require(fromTimestamp <= toTimestamp);
    //     (uint fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    //     (uint toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    //     _years = toYear - fromYear;
    // }

    // function diffMonths(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _months) {
    //     require(fromTimestamp <= toTimestamp);
    //     (uint fromYear, uint fromMonth, ) = _daysToDate(
    //         fromTimestamp / SECONDS_PER_DAY
    //     );
    //     (uint toYear, uint toMonth, ) = _daysToDate(
    //         toTimestamp / SECONDS_PER_DAY
    //     );
    //     _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    // }

    // function diffDays(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _days) {
    //     require(fromTimestamp <= toTimestamp);
    //     _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    // }

    // function diffHours(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _hours) {
    //     require(fromTimestamp <= toTimestamp);
    //     _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    // }

    // function diffMinutes(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _minutes) {
    //     require(fromTimestamp <= toTimestamp);
    //     _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    // }

    // function diffSeconds(
    //     uint fromTimestamp,
    //     uint toTimestamp
    // ) internal pure returns (uint _seconds) {
    //     require(fromTimestamp <= toTimestamp);
    //     _seconds = toTimestamp - fromTimestamp;
    // }
}
