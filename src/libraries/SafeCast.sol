// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library SafeCast {
    function toInt128(int256 y) internal pure returns (int128 z) {
        // -2**127 <= y <= 2**127 - 1
        require((z = int128(y)) == y);
    }
}
