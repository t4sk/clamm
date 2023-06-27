// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LiquidityDelta {
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x);
        } else {
            require((z = x + uint128(y)) >= x);
        }
    }
}
