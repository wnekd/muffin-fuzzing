// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./math/Math.sol";
import "./Constants.sol";
import "./TickMaps.sol";

library Ticks {
    using Math for uint128;
    using TickMaps for TickMaps.TickMap;

    struct Tick {
        int128 liquidityNet;
        uint128 liquidityGross; //          Act as initialization flag (0: not initialized)
        uint256 feeGrowthOutside0; //       UQ128.128
        uint256 feeGrowthOutside1; //       UQ128.128
        uint208 rewardGrowthOutside; //     UQ120.88
        int24 nextBelow; //                 Next initialized tick above
        int24 nextAbove; //                 Next initialized tick below
    }

    /// @dev Flip the direction of "outside". Called when crossing the tick.
    function flip(
        Tick storage self,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1,
        uint208 rewardGrowthGlobal
    ) internal {
        unchecked {
            self.feeGrowthOutside0 = feeGrowthGlobal0 - self.feeGrowthOutside0;
            self.feeGrowthOutside1 = feeGrowthGlobal1 - self.feeGrowthOutside1;
            self.rewardGrowthOutside = rewardGrowthGlobal - self.rewardGrowthOutside;
        }
    }

    function updateTick(
        mapping(int24 => Tick) storage ticks,
        TickMaps.TickMap storage tickMap,
        bool isLower,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1,
        uint208 rewardGrowthGlobal
    ) internal {
        Tick storage obj = ticks[tick];

        // initialize tick (48853)
        if (obj.liquidityGross == 0 && liquidityDelta > 0) {
            int24 below = tickMap.nextBelow(tick); // (12047 / 2779)
            int24 above = ticks[below].nextAbove; // (2238)
            obj.nextBelow = below; // (22265)
            obj.nextAbove = above;
            ticks[below].nextAbove = tick; // (8457)
            ticks[above].nextBelow = tick;
            tickMap.set(tick); // (3846)
        }

        // assume the past fees and rewards are generated _below_ the current tick (44497)
        if (obj.liquidityGross == 0 && tick <= tickCurrent) {
            obj.feeGrowthOutside0 = feeGrowthGlobal0;
            obj.feeGrowthOutside1 = feeGrowthGlobal1;
            obj.rewardGrowthOutside = rewardGrowthGlobal;
        }

        // add liquidity delta (21531)
        obj.liquidityNet += liquidityDelta * (isLower ? int128(1) : -1);
        obj.liquidityGross = obj.liquidityGross.addInt128(liquidityDelta);

        if (liquidityDelta > 0 && isLower) require(obj.liquidityNet <= Constants.MAX_LIQUIDITY_NET);
    }

    function deleteIfEmpty(
        mapping(int24 => Tick) storage ticks,
        TickMaps.TickMap storage tickMap,
        int24 tick
    ) internal returns (bool deleted) {
        Tick storage obj = ticks[tick];

        if (obj.liquidityGross == 0) {
            int24 below = obj.nextBelow;
            int24 above = obj.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;

            delete ticks[tick];
            tickMap.unset(tick);
            deleted = true;
        }
    }
}
