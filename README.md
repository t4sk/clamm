# CLAMM - Concentrated liquidity AMM

https://github.com/Uniswap/v3-core

https://github.com/Uniswap/v3-periphery

### Uni V3 pool

ETH / USDC 0.05% pool Arbitrum

0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443

### Omit

-   Factory
-   Price oracle
-   Protocol fee
-   Flash swap
-   NFT
-   Solidity advanced math libraries
-   Callbacks

-   ### Setup

```shell
forge init clamm
forge build
forge fmt
```

-   ### Constructor
    -   [ ] `constructor`
        -   [ ] Price, tick and tick spacing
        -   [ ] `tickSpacingToMaxLiquidityPerTick`
-   ### Initialize
    -   [ ] `initialize`
        -   [ ] `sqrtPriceX96`, `getTickAtSqrtRatio`, calculate tick from `sqrtPriceX96`
        -   [ ] `slot0`
-   ### Mint
    -   [ ] `mint`
        -   [ ] `_modifyPosition`
            -   [ ] `_updatePosition`
                -   [ ] `Tick.update`
                    -   [ ] Liquidity, price and token reserves
                    -   [ ] Liquidity net
            -   [ ] `getSqrtRatioAtTick`
            -   [ ] Curve of real reserves
            -   [ ] Reserve 0 and reserve 1
            -   [ ] Liquidity, amount 0 and 1 delta
            -   [ ] Liquidity delta
-   ### Burn
-   ### Collect
-   ### Swap
-   ### Fees
-   ### Test

-   sqrtPriceX96
-   get tick from sqrt price x 96
-   get price from sqrt price x 96
-   tick bitmap
-   getSqrtRatioAtTick
-   getTickAtSqrtRatio
-   getAmount0Delta, getAmount1Delta
-   liquidity delta
-   tick, liquidity, price directions and token 0 token 1
-   getNextSqrtPriceFromAmount0RoundingUp(
-   getNextSqrtPriceFromAmount1RoundingDown
-   why `fee = amountIN * fee / (1 - fee)`
-   nextInitializedTickWithinOneWord
-   liquidityNet
-   fee growth (per liquidity)
-   how does burn update tokensOwed

TODO: - fees, sort topics
