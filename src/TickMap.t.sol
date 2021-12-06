// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "@deliswap-muffin/libraries/TickMaps.sol";
import "@deliswap-muffin/libraries/Constants.sol";

contract TickMapTest is DSTest {
    using TickMaps for TickMaps.TickMap;

    TickMaps.TickMap public tickMap;

    function _normalize(int24 tick) internal pure returns (int24) {
        if (tick < Constants.MIN_TICK) return tick % Constants.MIN_TICK;
        if (tick > Constants.MAX_TICK) return tick % Constants.MAX_TICK;
        return tick;
    }

    function test_nextBelow(int24 tick1, int24 tick2) external {
        // skip or normalize unwanted params
        if (tick1 == tick2) return;
        tick1 = _normalize(tick1);
        tick2 = _normalize(tick2);

        // set ticks
        tickMap.set(tick1);
        tickMap.set(tick2);

        // sort ticks
        if (tick1 > tick2) (tick1, tick2) = (tick2, tick1);

        // check tick2.nextBelow is tick1
        assertEq(tickMap.nextBelow(tick2), tick1);
    }
}
