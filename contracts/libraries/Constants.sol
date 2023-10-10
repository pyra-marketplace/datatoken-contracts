// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Constants {
    address internal constant ZERO_ADDRESS = address(0);

    uint256 internal constant BASIS_POINTS = 10000; // royaltyInfo

    uint256 internal constant FEE_RATE_BPS = 10000;

    uint24 internal constant ONE_DAY = 24 hours;
}
