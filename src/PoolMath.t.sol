// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "@deliswap-muffin/libraries/math/PoolMath.sol";

contract PoolMathTest is DSTest {
    uint256 private constant Q72 = 0x1000000000000000000;
    uint256 private constant Q184 = 0x10000000000000000000000000000000000000000000000;

    function abs(int256 x) internal pure returns (uint256 z) {
        unchecked {
            z = x < 0 ? uint256(-x) : uint256(x);
        }
    }

    function test_calcAmt0FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) external {
        if (sqrtP0 == 0) return;
        if (sqrtP1 == 0) return;
        if (liquidity == 0) return;

        int256 amt0 = PoolMath.calcAmt0FromSqrtP(sqrtP0, sqrtP1, liquidity);
        int256 amt0Reversed = PoolMath.calcAmt0FromSqrtP(sqrtP1, sqrtP0, liquidity);

        // check amt0's sign and rounding
        if (sqrtP0 > sqrtP1) {
            // amt0 is input
            assertGt(amt0, 0);
            assertLe(abs(amt0) - abs(amt0Reversed), 1);
        } else if (sqrtP0 < sqrtP1) {
            // amt0 is output
            assertLe(amt0, 0);
            assertLe(abs(amt0Reversed) - abs(amt0), 1);
        } else {
            assertEq(amt0, 0);
            assertEq(amt0, amt0Reversed);
        }
    }

    function test_calcAmt1FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) external {
        if (sqrtP0 == 0) return;
        if (sqrtP1 == 0) return;
        if (liquidity == 0) return;

        int256 amt1 = PoolMath.calcAmt1FromSqrtP(sqrtP0, sqrtP1, liquidity);
        int256 amt1Reversed = PoolMath.calcAmt1FromSqrtP(sqrtP1, sqrtP0, liquidity);

        // check amt1's sign and rounding
        if (sqrtP0 > sqrtP1) {
            // amt1 is output
            assertLe(amt1, 0);
            assertLe(abs(amt1Reversed) - abs(amt1), 1);
        } else if (sqrtP0 < sqrtP1) {
            // amt1 is input
            assertGt(amt1, 0);
            assertLe(abs(amt1) - abs(amt1Reversed), 1);
        } else {
            assertEq(amt1, 0);
            assertEq(amt1, amt1Reversed);
        }
    }

    function test_calcSqrtPFromAmt0(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt0
    ) external {
        if (sqrtP0 == 0) return;
        if (liquidity == 0) return;

        // make sure the desired output amount is not larger than the pool reserve
        uint256 reserve0RoundDown = (uint256(liquidity) * Q72) / sqrtP0;
        if (amt0 < 0 && abs(amt0) > reserve0RoundDown) {
            if (reserve0RoundDown == 0) return;
            amt0 = -Math.toInt256(abs(amt0) % reserve0RoundDown);
        }

        // skip if the calculation is going to overflow / underflow
        if (amt0 < 0) {
            unchecked {
                uint256 liquidityX72 = uint256(liquidity) << 72;
                uint256 product;
                uint256 denom;
                if ((product = abs(amt0) * sqrtP0) / abs(amt0) != sqrtP0) return;
                if ((denom = liquidityX72 - product) > liquidityX72 || (denom == 0)) return;
                if (FullMath.mulDivRoundingUp(uint256(liquidity) * sqrtP0, Q72, denom) > type(uint128).max) return;
            }
        }

        uint128 sqrtP1 = PoolMath.calcSqrtPFromAmt0(sqrtP0, liquidity, amt0);
        if (amt0 > 0) {
            assertLe(sqrtP1, sqrtP0); // amt0 is input  => price should go down or stay still
        } else if (amt0 < 0) {
            assertGt(sqrtP1, sqrtP0); // amt0 is output => price should go up
        } else {
            assertEq(sqrtP1, sqrtP0);
        }
    }

    function test_calcSqrtPFromAmt1(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt1
    ) external {
        if (sqrtP0 == 0) return;
        if (liquidity == 0) return;

        // make sure the desired output amount is not larger than the pool reserve
        uint256 reserve1RoundDown = (uint256(liquidity) * sqrtP0) / Q72;
        if (amt1 < 0 && abs(amt1) > reserve1RoundDown) {
            if (reserve1RoundDown == 0) return;
            amt1 = -Math.toInt256(abs(amt1) % reserve1RoundDown);
        }

        // skip if the calculation is going to overflow / underflow
        if (amt1 >= 0) {
            unchecked {
                uint256 absAmt1 = uint256(amt1);
                uint256 absAmt1DivLX72 = (absAmt1 / liquidity) * Q72;
                if (absAmt1DivLX72 != 0 && (absAmt1DivLX72 * Q72) / absAmt1DivLX72 != Q72) return;
                if (uint256(sqrtP0) + FullMath.mulDiv(absAmt1, Q72, liquidity) > type(uint128).max) return;
            }
        }

        uint128 sqrtP1 = PoolMath.calcSqrtPFromAmt1(sqrtP0, liquidity, amt1);
        if (amt1 > 0) {
            assertGe(sqrtP1, sqrtP0); // amt1 is input  => price should go up or stay still
        } else if (amt1 < 0) {
            assertLt(sqrtP1, sqrtP0); // amt1 is output => price should go down
        } else {
            assertEq(sqrtP1, sqrtP0);
        }
    }

    function test_calcAmtsForLiquidity(
        uint128 sqrtP,
        uint128 sqrtPLower,
        uint128 sqrtPUpper,
        int128 liquidityDelta
    ) external {
        if (sqrtP == 0) return;
        if (sqrtPLower == 0) return;
        if (sqrtPUpper == 0) return;
        if (sqrtPLower > sqrtPUpper) return;

        (uint256 amt0, uint256 amt1) = PoolMath.calcAmtsForLiquidity(sqrtP, sqrtPLower, sqrtPUpper, liquidityDelta);

        if (liquidityDelta == 0 || sqrtPLower == sqrtPUpper) {
            assertEq(amt0, 0);
            assertEq(amt1, 0);
        } else if (liquidityDelta > 0) {
            assertTrue(amt0 > 0 || amt1 > 0);
        }

        // check single-sided deposit
        if (sqrtP <= sqrtPLower) assertEq(amt1, 0);
        if (sqrtP >= sqrtPUpper) assertEq(amt0, 0);

        // check amt{0,1} rounded up/down when adding/removing liquidity
        if (liquidityDelta != type(int128).min) {
            (uint256 amt0Reversed, uint256 amt1Reversed) = PoolMath.calcAmtsForLiquidity(
                sqrtP,
                sqrtPLower,
                sqrtPUpper,
                -liquidityDelta
            );

            (uint256 amt0In, uint256 amt1In, uint256 amt0Out, uint256 amt1Out) = liquidityDelta > 0
                ? (amt0, amt1, amt0Reversed, amt1Reversed)
                : (amt0Reversed, amt1Reversed, amt0, amt1);
            assertLe(amt0In - amt0Out, 1, "amt0In is at most larger than amt0Out by 1");
            assertLe(amt1In - amt1Out, 1, "amt1In is at most larger than amt1Out by 1");
        }
    }
}
