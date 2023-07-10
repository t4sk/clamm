// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./FullMath.sol";
import "./SqrtPriceMath.sol";

library SwapMath {
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        // 1e6 = 100%
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            // Calculate max amount in
            uint256 amountRemainingLessFee =
                FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(
                    sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true
                )
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true
                );
            // Calculate next sqrt ratio
            if (amountRemainingLessFee >= amountIn) {
                sqrtRatioNextX96 = sqrtRatioTargetX96;
            } else {
                // next sqrt ratio is between sqrt current and sqrt target
                // zero for one = target <= next <= current
                // one for zero = current <= next <= target
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
            }
        } else {
            // Calculate max amount out
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(
                    sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false
                )
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false
                );
            // Calculate next sqrt ratio
            if (uint256(-amountRemaining) >= amountOut) {
                sqrtRatioNextX96 = sqrtRatioTargetX96;
            } else {
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
            }
        }

        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // Get input / output amounts between sqrt current and next
        // max and exactIn   --> in  = amountIn
        //                       out = need to calculate
        // max and !exactIn  --> in  = need to calculate
        //                       out = amountOut
        // !max and exactIn  --> in  = need to calculate
        //                       out = need to calculate
        // !max and !exactIn --> in  = need to calculate
        //                       out = need to calculate
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                // next <= current, round up amount in
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true
                );
            amountOut = max && !exactIn
                ? amountOut
                // next <= current, round down amount out
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false
                );
        } else {
            amountIn = max && exactIn
                ? amountIn
                // current <= next, round up amount in
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true
                );
            amountOut = max && !exactIn
                ? amountOut
                // current <= next, round down amount out
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false
                );
        }

        // NOTE - safety check
        // Cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        // Calculate fee on amount in
        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // TODO: what? - Take the remainder of the maximum input as fee
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            // TODO: why fee = amountIN * fee / (1 - fee)
            feeAmount =
                FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}
