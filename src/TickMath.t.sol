// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {TickMath as TM} from "@deliswap-muffin/libraries/math/TickMath.sol";

contract TickMathTest is DSTest {
    function test_tickToSqrtP(int24 tick) external {
        if (tick < TM.MIN_TICK || tick > TM.MAX_TICK) return;
        uint128 sqrtP = TM.tickToSqrtP(tick);

        // check sqrtP is in valid range
        assertTrue(sqrtP >= TM.MIN_SQRT_P && sqrtP <= TM.MAX_SQRT_P);

        // check sqrtP must increase / decrease as the tick increases / decreases
        if (tick != TM.MIN_TICK) assertTrue(sqrtP > TM.tickToSqrtP(tick - 1));
        if (tick != TM.MAX_TICK) assertTrue(sqrtP < TM.tickToSqrtP(tick + 1));
    }

    function test_sqrtPToTick(uint128 sqrtP) external {
        if (sqrtP < TM.MIN_SQRT_P || sqrtP > TM.MAX_SQRT_P) return;
        int24 tick = TM.sqrtPToTick(sqrtP);

        // check tick is in valid range
        assertTrue(tick >= TM.MIN_TICK && tick <= TM.MAX_TICK);

        // check sqrtPTick ≤ sqrtP < sqrtPNextTick
        assertTrue(sqrtP >= TM.tickToSqrtP(tick));
        if (tick != TM.MAX_TICK) assertTrue(sqrtP < TM.tickToSqrtP(tick + 1));
    }

    function test_duality(int24 tick) external {
        if (tick < TM.MIN_TICK || tick > TM.MAX_TICK) return;
        assertEq(tick, TM.sqrtPToTick(TM.tickToSqrtP(tick)));
    }
}
