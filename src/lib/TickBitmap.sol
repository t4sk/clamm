// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./BitMath.sol";

library TickBitmap {
    // TODO: position also valid for tick < 0?
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

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        // true = seatch to the left
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        // Round down to negative infinity
        if (tick < 0 && tick % tickSpacing != 0) {
            compressed--;
        }

        if (lte) {
            // Search lesser or equal tick = bit to the right of current bit position
            (int16 wordPos, uint8 bitPos) = position(compressed);

            // All 1s at or to the right of bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;

            // nect = (compressed - remove bit pos + right most bit of masked) * tick spacing
            //      = (compressed - bit pos        + msb(masked)) * tick spacing
            next = initialized
                ? (
                    compressed
                        - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))
                ) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            // Search greater tick = bit to the left of current bit position
            // Start search from next tick
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // All 1s at or to the left of bitPos
            // 1 << bitPos = 1 at bitPos
            // (1 << bitPos) - 1 = All 1s to the right of bitPos
            // ~((1 << bit) - 1) = All 1s at or to the left of bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;

            // next = (next compressed tick + left most bit of masked  - remove bit pos) * tick spacing
            //      = (compressed + 1       + lsb(masked)              - bit pos) * tick spacing
            next = initialized
                ? (
                    compressed + 1
                        + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))
                ) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos)))
                    * tickSpacing;
        }
    }
}
