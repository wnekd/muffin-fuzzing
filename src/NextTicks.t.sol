// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "@deliswap-muffin/libraries/NextTicks.sol";
import "@deliswap-muffin/libraries/Constants.sol";

contract NextTicksTest is DSTest {
    using NextTicks for NextTicks.Info;

    NextTicks.Info internal nextTicks;

    function _normalize(int24 tick) internal pure returns (int24) {
        if (tick < Constants.MIN_TICK) return tick % Constants.MIN_TICK;
        if (tick > Constants.MAX_TICK) return tick % Constants.MAX_TICK;
        return tick;
    }

    function test_getSet_storage(
        bool below,
        uint8 tierId,
        int24 tick
    ) external {
        tierId %= 6;
        tick = _normalize(tick);

        if (below) {
            nextTicks.setBelow(tierId, tick);
            assertEq(nextTicks.getBelow(tierId), tick);
        } else {
            nextTicks.setAbove(tierId, tick);
            assertEq(nextTicks.getAbove(tierId), tick);
        }
    }

    function test_getSet_memory(
        uint8 tierId,
        int24 tickBelow,
        int24 tickAbove
    ) external {
        tierId %= 6;
        tickBelow = _normalize(tickBelow);
        tickAbove = _normalize(tickAbove);
        if (tickBelow > tickAbove) (tickBelow, tickAbove) = (tickAbove, tickBelow);

        NextTicks.Info memory _nextTicks;
        _nextTicks.set(tierId, tickBelow, tickAbove);
        assertEq(_nextTicks.get(true, tierId), tickBelow);
        assertEq(_nextTicks.get(false, tierId), tickAbove);
    }

    function test_insert(
        uint8 tierId,
        int24 tickNext,
        int24 tickNew,
        int24 tickCurrent
    ) external {
        tierId %= 6;
        tickNext = _normalize(tickNext);
        tickNew = _normalize(tickNew);
        tickCurrent = _normalize(tickCurrent);

        if (tickNext <= tickCurrent) {
            nextTicks.setBelow(tierId, tickNext);
        } else {
            nextTicks.setAbove(tierId, tickNext);
        }

        nextTicks.insert(tierId, tickNew, tickCurrent);

        if (tickNext <= tickNew && tickNew <= tickCurrent) assertEq(tickNew, nextTicks.getBelow(tierId));
        if (tickCurrent < tickNew && tickNew <= tickNext) assertEq(tickNew, nextTicks.getAbove(tierId));
    }
}
