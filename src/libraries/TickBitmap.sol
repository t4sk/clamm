// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library TickBitmap {
    function position(int24 tick)
        private
        pure
        returns (int16 wordPos, uint8 bitPos)
    {
        // Shift right last 8 bits
        wordPos = int16(tick >> 8);
        // Last 8 bits
        bitPos = uint8(uint24(tick % 256));
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0);
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        // 0 <= uint8 <= 2**8 - 1 = 255
        // mask = 1 at bit position, rest are 0
        uint256 mask = 1 << bitPos;
        // xor
        self[wordPos] ^= mask;
    }
}
