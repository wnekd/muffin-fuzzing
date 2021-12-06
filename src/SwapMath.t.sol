// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "@deliswap-muffin/libraries/math/SwapMath.sol";
import "@deliswap-muffin/libraries/Constants.sol";
import "@deliswap-muffin/libraries/Tiers.sol";

contract SwapMathTest is DSTest {
    using SqrtGammaMap for uint104;

    /// @dev The number of tiers in the pool in the test cases
    uint256 internal constant SIZE = 6;

    int256 internal constant REJECTED = type(int256).max;

    function _prepareParams(
        uint16[SIZE] memory sqrtGammaSeeds,
        uint128[SIZE] memory sqrtPrices,
        uint128[SIZE] memory liquiditys,
        uint8 _tierChoices
    )
        internal
        pure
        returns (
            Tiers.Tier[] memory tiers,
            uint104 sqrtGammaMap,
            uint256 tierChoices
        )
    {
        unchecked {
            // prepare tierChoices
            tierChoices = uint256(_tierChoices) & ((1 << SIZE) - 1);
            if (tierChoices == 0) tierChoices = 0x3F; // 0b111111

            // prepare tiers
            tiers = new Tiers.Tier[](sqrtPrices.length);
            for (uint256 i; i < tiers.length; i++) {
                tiers[i].sqrtP = sqrtPrices[i];
                tiers[i].liquidity = liquiditys[i];
            }

            // prepare sqrtGammaMap
            for (uint8 i; i < tiers.length; i++) {
                // filter sqrtGamma to be [90000, 100000], to be realistic
                uint24 sqrtGamma = uint24(100_000) - (uint24(sqrtGammaSeeds[i]) % 10000);
                sqrtGammaMap = sqrtGammaMap.set(i, sqrtGamma);
            }
        }
    }

    function test_calcTierAmtsIn(
        bool isToken0,
        uint256 amountIn,
        uint16[SIZE] memory sqrtGammaSeeds,
        uint128[SIZE] memory sqrtPrices,
        uint128[SIZE] memory liquiditys,
        uint8 _tierChoices
    ) external {
        // skip unwanted settings
        for (uint256 i; i < sqrtPrices.length; i++) {
            if (sqrtPrices[i] < Constants.MIN_SQRT_P) return;
            if (sqrtPrices[i] > Constants.MAX_SQRT_P) return;
            if (liquiditys[i] < Constants.BASE_LIQUIDITY) return;
        }
        if (amountIn == 0) return;
        if (amountIn > uint256(type(int256).max)) return;

        // prepare params
        (Tiers.Tier[] memory tiers, uint104 sqrtGammaMap, uint256 tierChoices) = _prepareParams(
            sqrtGammaSeeds,
            sqrtPrices,
            liquiditys,
            _tierChoices
        );

        // perform calculation
        int256 amtDesired = int256(amountIn);
        int256[] memory amtIns = SwapMath.calcTierAmtsIn(isToken0, amtDesired, sqrtGammaMap, tiers, tierChoices);

        // check results
        int256 sumAmtIn;
        for (uint256 i; i < tiers.length; i++) {
            if (amtIns[i] == REJECTED) continue;
            assertTrue(amtIns[i] >= 0);
            sumAmtIn += amtIns[i];
        }
        assertLe(sumAmtIn, amtDesired, "actual amountIn must be smaller than desired amountIn");
        assertLe(amtDesired - sumAmtIn, 5, "actual amountIn cannot be smaller than desired amountIn by more than 5");
        if (amtDesired >= 3) assertGt(sumAmtIn, 0, "actual amountIn must be non-zero if desired amountIn >= 3");
    }

    function test_calcTierAmtsOut(
        bool isToken0,
        uint256 amountOut,
        uint16[SIZE] memory sqrtGammaSeeds,
        uint128[SIZE] memory sqrtPrices,
        uint128[SIZE] memory liquiditys,
        uint8 _tierChoices
    ) external {
        // skip unwanted settings
        for (uint256 i; i < sqrtPrices.length; i++) {
            if (sqrtPrices[i] < Constants.MIN_SQRT_P) return;
            if (sqrtPrices[i] > Constants.MAX_SQRT_P) return;
            if (liquiditys[i] < Constants.BASE_LIQUIDITY) return;
        }
        unchecked {
            if (amountOut == 0) return;
            if (amountOut > uint256(-type(int256).min)) return;
        }

        // prepare params
        (Tiers.Tier[] memory tiers, uint104 sqrtGammaMap, uint256 tierChoices) = _prepareParams(
            sqrtGammaSeeds,
            sqrtPrices,
            liquiditys,
            _tierChoices
        );

        // perform calculation
        int256 amtDesired = int256(type(uint256).max - amountOut + 1);
        int256[] memory amtOuts = SwapMath.calcTierAmtsOut(isToken0, amtDesired, sqrtGammaMap, tiers, tierChoices);

        // check results
        int256 sumAmtOut;
        for (uint256 i; i < tiers.length; i++) {
            if (amtOuts[i] == REJECTED) continue;
            assertTrue(amtOuts[i] <= 0);
            sumAmtOut += amtOuts[i];
        }
        assertGe(sumAmtOut, amtDesired, "actual amountOut must be smaller than desired amountOut");
        assertLe(sumAmtOut - amtDesired, 5, "actual amountOut cannot be smaller than desired amountOut by more than 5");
        if (amtDesired <= -2) assertLt(sumAmtOut, 0, "actual amountOut must be non-zero if desired amountOut >= 2");
    }

    function test_computeStep(
        bool isToken0,
        bool exactIn,
        int256 amount,
        uint128 sqrtP,
        uint128 sqrtPTick,
        uint128 liquidity,
        uint16 sqrtGammaSeed
    ) external {
        // skip unwanted settings
        if (sqrtP < Constants.MIN_SQRT_P || sqrtP > Constants.MAX_SQRT_P) return;
        if (sqrtPTick < Constants.MIN_SQRT_P || sqrtPTick > Constants.MAX_SQRT_P) return;
        if (liquidity < Constants.BASE_LIQUIDITY) return;

        // switch the sign of amount if neccessary
        if (exactIn) {
            if (amount < 0) {
                if (amount == type(int256).min) return;
                else amount *= -1;
            }
        } else {
            if (amount > 0) amount *= -1;
        }

        // switch sqrtP and sqrtPTick if neccessary
        if (isToken0 == exactIn) {
            if (sqrtPTick > sqrtP) (sqrtPTick, sqrtP) = (sqrtP, sqrtPTick);
        } else {
            if (sqrtPTick < sqrtP) (sqrtPTick, sqrtP) = (sqrtP, sqrtPTick);
        }

        // perform calculation
        uint24 sqrtGamma = uint24(1e5) - (uint24(sqrtGammaSeed) % 10000); // = [90000, 100000] to be realistic
        (int256 amtA, int256 amtB, uint128 sqrtPNew, uint256 feeAmt) = SwapMath.computeStep(
            isToken0,
            exactIn,
            amount,
            sqrtP,
            sqrtPTick,
            liquidity,
            sqrtGamma
        );

        // check the signs of amtA and amtB. check amtA is not larger than the given amount
        if (exactIn) {
            assertTrue(0 <= amtA && amtA <= amount);
            assertTrue(amtB <= 0);
        } else {
            assertTrue(amount <= amtA && amtA <= 0);
            assertTrue(amtB >= 0);
        }

        // check new sqrtP is in between previous sqrtP and the tick sqrtP
        if (isToken0 == exactIn) {
            assertTrue(sqrtPNew <= sqrtP);
            assertTrue(sqrtPNew >= sqrtPTick);
        } else {
            assertTrue(sqrtPNew >= sqrtP);
            assertTrue(sqrtPNew <= sqrtPTick);
        }

        // check we used up all given amount if the new sqrtP doesn't hit tick sqrtP
        if (sqrtPNew != sqrtPTick) {
            assertEq(amount, amtA);
        }

        // check feeAmt must be lower than or equal to (input amt * fee bps)
        uint256 amtIn = uint256(exactIn ? amtA : amtB);
        uint256 maxFeeAmt = FullMath.mulDivRoundingUp(amtIn, 1e10 - (uint256(sqrtGamma) * sqrtGamma), 1e10);
        if (sqrtPNew == sqrtPTick) {
            assertTrue(feeAmt <= maxFeeAmt);
        } else {
            assertEq(feeAmt, maxFeeAmt);
        }

        // check feeAmt is not zero when sqrt price moved and percentage fee is non-zero
        if (sqrtP != sqrtPNew && sqrtGamma != 1e5) {
            assertTrue(feeAmt > 0);
        }

        // check amtA, amtB, feeAmt are all zero if sqrt price didn't move
        if (sqrtP == sqrtPNew) {
            assertEq(amtA, 0);
            assertEq(amtB, 0);
            assertEq(feeAmt, 0);
        }

        // check if tier is rejected
        if (amtA == REJECTED) {
            assertEq(amtB, 0);
            assertEq(sqrtPNew, sqrtP);
            assertEq(feeAmt, 0);
        }
    }
}
