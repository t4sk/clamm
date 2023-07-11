# Topics

-   ### Setup

```shell
forge init clamm
forge build
forge fmt
```

-   ### Constructor
    -   `constructor`
    -   Tick and tick spacing
-   ### Initialize
    -   `initialize`
    -   `sqrtPriceX96`
    -   `getTickAtSqrtRatio`
    -   `slot0`
-   ### Mint
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

TODO: - fees, sort topics, code review, test

### omit

-   price oracle
-   protocol fee
-   flash swap
-   nft
-   solidity advanced math libraries
-   Callbacks
