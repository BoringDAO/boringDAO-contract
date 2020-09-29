// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}