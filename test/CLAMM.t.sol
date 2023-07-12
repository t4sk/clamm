// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./ERC20.sol";
import "./lib/LiquidityAmounts.sol";
import "../src/lib/TickMath.sol";
import "../src/CLAMM.sol";

contract ClammTest is Test {
    ERC20 private token0;
    ERC20 private token1;
    CLAMM private clamm;

    // 0.05%
    uint24 private constant FEE = 500;
    int24 private constant TICK_SPACING = 10;

    address[] private users = [address(1), address(2)];

    // about $1851 = SQRT_P0 * SQRT_P0 / 2**96 / 2**96 * (1e18 / 1e6)
    uint160 private constant SQRT_P0 = 3409290029545542707626329;

    function setUp() public {
        // token 0 = ETH
        // token 1 = USD
        while (address(token0) >= address(token1)) {
            token0 = new ERC20("ETH", "ETH", 18);
            token1 = new ERC20("USD", "USD", 6);
        }

        clamm = new CLAMM(address(token0), address(token1), FEE, TICK_SPACING);

        clamm.initialize(SQRT_P0);

        for (uint256 i = 0; i < users.length; i++) {
            token0.mint(users[i], 1e27);
            token1.mint(users[i], 1e27);

            vm.startPrank(users[i]);
            token0.approve(address(clamm), type(uint256).max);
            token1.approve(address(clamm), type(uint256).max);
            vm.stopPrank();
        }
    }

    function testSinglePositionSwap() public {
        // Add liquidity //
        Slot0 memory slot0 = clamm.getSlot0();

        uint256 amount0Desired = 1_000_000 * 1e18;
        uint256 amount1Desired = 1_000_000 * 1e6;

        int24 tickLower =
            (slot0.tick - TICK_SPACING) / TICK_SPACING * TICK_SPACING;
        int24 tickUpper =
            (slot0.tick + TICK_SPACING) / TICK_SPACING * TICK_SPACING;
        uint160 sqrtRatioLowerX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioUpperX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            slot0.sqrtPriceX96,
            sqrtRatioLowerX96,
            sqrtRatioUpperX96,
            amount0Desired,
            amount1Desired
        );

        {
            vm.prank(users[0]);

            (uint256 amount0, uint256 amount1) =
                clamm.mint(users[0], tickLower, tickUpper, liquidity);

            console.log("add liquidity - amount 0:", floor(amount0, 1e18));
            console.log("add liquidity - amount 1:", floor(amount1, 1e6));
        }

        // Swap (1 for 0, exact input) //
        {
            int256 amountIn = 1000 * 1e6;

            vm.prank(users[1]);
            (int256 amount0Delta, int256 amount1Delta) =
                clamm.swap(users[1], false, amountIn, sqrtRatioUpperX96);

            // Print amount 0 and 1 delta, split into whole num and decimal parts
            // + amount in
            // - amount out
            if (amount0Delta < 0) {
                uint256 d = uint256(-amount0Delta);
                console.log(
                    "swap - amount 0 out:", floor(d, 1e18), rem(d, 1e18, 1e15)
                );
            } else {
                uint256 d = uint256(amount0Delta);
                console.log(
                    "swap - amount 0 in:", floor(d, 1e18), rem(d, 1e18, 1e15)
                );
            }
            if (amount1Delta < 0) {
                uint256 d = uint256(-amount1Delta);
                console.log(
                    "swap - amount 1 out:", floor(d, 1e6), rem(d, 1e6, 1e3)
                );
            } else {
                uint256 d = uint256(amount1Delta);
                console.log(
                    "swap - amount 1 in:", floor(d, 1e6), rem(d, 1e6, 1e3)
                );
            }
        }

        // Burn + collect //
        {
            Position.Info memory pos =
                clamm.getPosition(users[0], tickLower, tickUpper);

            vm.prank(users[0]);
            (uint256 a0Burned, uint256 a1Burned) =
                clamm.burn(tickLower, tickUpper, pos.liquidity);

            console.log("remove liquidity - amount 0:", a0Burned);
            console.log("remove liquidity - amount 1:", a1Burned);

            vm.prank(users[0]);
            (uint128 a0Collected, uint128 a1Collected) = clamm.collect(
                users[1],
                tickLower,
                tickUpper,
                type(uint128).max,
                type(uint128).max
            );

            console.log("collect - amount 0:", a0Collected);
            console.log("collect - amount 1:", a1Collected);

            console.log("fee 0:", a0Collected - a0Burned);
            console.log("fee 1:", a1Collected - a1Burned);
        }
    }

    struct AddLiquidityParams {
        address user;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    // TODO: test multi liquidity swaps (HERE)
    function testMultiPositionsSwap() public {
        // Add liquidity //
        Slot0 memory slot0 = clamm.getSlot0();

        AddLiquidityParams[2] memory addParams = [
            AddLiquidityParams({
                user: users[0],
                tickLower: (slot0.tick - TICK_SPACING) / TICK_SPACING * TICK_SPACING,
                tickUpper: (slot0.tick + TICK_SPACING) / TICK_SPACING * TICK_SPACING,
                amount0Desired: 1_000_000 * 1e18,
                amount1Desired: 1_000_000 * 1e6
            }),
            AddLiquidityParams({
                user: users[0],
                tickLower: (slot0.tick - 3 * TICK_SPACING) / TICK_SPACING * TICK_SPACING,
                tickUpper: (slot0.tick + 3 * TICK_SPACING) / TICK_SPACING * TICK_SPACING,
                amount0Desired: 1_000_000 * 1e18,
                amount1Desired: 1_000_000 * 1e6
            })
        ];

        {
            console.log("--- Add liquidity ---");

            for (uint256 i = 0; i < addParams.length; i++) {
                uint160 sqrtRatioLowerX96 =
                    TickMath.getSqrtRatioAtTick(addParams[i].tickLower);
                uint160 sqrtRatioUpperX96 =
                    TickMath.getSqrtRatioAtTick(addParams[i].tickUpper);

                uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
                    slot0.sqrtPriceX96,
                    sqrtRatioLowerX96,
                    sqrtRatioUpperX96,
                    addParams[i].amount0Desired,
                    addParams[i].amount1Desired
                );

                vm.prank(addParams[i].user);

                (uint256 amount0, uint256 amount1) = clamm.mint(
                    users[0],
                    addParams[i].tickLower,
                    addParams[i].tickUpper,
                    liquidity
                );

                console.log("add liquidity - amount 0:", floor(amount0, 1e18));
                console.log("add liquidity - amount 1:", floor(amount1, 1e6));

                if (addParams[i].tickLower >= 0) {
                    console.log("tick lower:", uint24(addParams[i].tickLower));
                } else {
                    console.log(
                        "tick lower: -", uint24(-addParams[i].tickLower)
                    );
                }
                if (addParams[i].tickUpper >= 0) {
                    console.log(
                        "tick tickUpper:", uint24(addParams[i].tickUpper)
                    );
                } else {
                    console.log(
                        "tick tickUpper: -", uint24(-addParams[i].tickUpper)
                    );
                }

                console.log("liquidity:", liquidity);
            }
        }

        // Swap (1 for 0, exact input) //
        {
            console.log("--- Swap ---");

            int256 amountIn = 1e9 * 1e6;

            vm.prank(users[1]);
            (int256 amount0Delta, int256 amount1Delta) = clamm.swap(
                users[1], false, amountIn, TickMath.MAX_SQRT_RATIO - 1
            );

            // Print amount 0 and 1 delta, split into whole num and decimal parts
            // + amount in
            // - amount out
            if (amount0Delta < 0) {
                uint256 d = uint256(-amount0Delta);
                console.log(
                    "swap - amount 0 out:", floor(d, 1e18), rem(d, 1e18, 1e15)
                );
            } else {
                uint256 d = uint256(amount0Delta);
                console.log(
                    "swap - amount 0 in:", floor(d, 1e18), rem(d, 1e18, 1e15)
                );
            }
            if (amount1Delta < 0) {
                uint256 d = uint256(-amount1Delta);
                console.log(
                    "swap - amount 1 out:", floor(d, 1e6), rem(d, 1e6, 1e3)
                );
            } else {
                uint256 d = uint256(amount1Delta);
                console.log(
                    "swap - amount 1 in:", floor(d, 1e6), rem(d, 1e6, 1e3)
                );
            }
        }

        // Burn + collect //
        {
            console.log("--- Burn + collect ---");

            for (uint256 i = 0; i < addParams.length; i++) {
                Position.Info memory pos = clamm.getPosition(
                    addParams[i].user,
                    addParams[i].tickLower,
                    addParams[i].tickUpper
                );

                vm.prank(addParams[i].user);
                (uint256 a0Burned, uint256 a1Burned) = clamm.burn(
                    addParams[i].tickLower,
                    addParams[i].tickUpper,
                    pos.liquidity
                );

                console.log("remove liquidity - amount 0:", a0Burned);
                console.log("remove liquidity - amount 1:", a1Burned);

                vm.prank(addParams[i].user);
                (uint128 a0Collected, uint128 a1Collected) = clamm.collect(
                    addParams[i].user,
                    addParams[i].tickLower,
                    addParams[i].tickUpper,
                    type(uint128).max,
                    type(uint128).max
                );

                console.log("collect - amount 0:", a0Collected);
                console.log("collect - amount 1:", a1Collected);

                console.log("fee 0:", a0Collected - a0Burned);
                console.log("fee 1:", a1Collected - a1Burned);
            }
        }
    }
}

function floor(uint256 x, uint256 d) returns (uint256) {
    return x / d;
}

function rem(uint256 x, uint256 d, uint256 p) returns (uint256) {
    uint256 r = x - (x / d * d);
    return r / p;
}
