// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./math/TickMath.sol";
import "./math/EMAMath.sol";
import "./Tiers.sol";

library TWAP {
    struct Info {
        uint32 lastUpdate;
        int56 tickCumulative; //    tick * secs elapsed
        int24 tickEma15; //         tick 15-min EMA
        int24 tickEma30; //         tick 30-min EMA
        int24 tickEma60; //         tick 60-min EMA
    }

    uint256 private constant Q64 = 0x10000000000000000;

    /// @param self The TWAP object
    /// @param tiers All tiers in the pool
    /// @return sumL Sum of liquidity of all tiers
    function update(Info storage self, Tiers.Tier[] memory tiers) internal returns (uint256 sumL) {
        unchecked {
            int256 sumLTick; // sum of liquidity * tick  (Q24 * UQ128)
            for (uint256 i; i < tiers.length; i++) {
                Tiers.Tier memory tier = tiers[i];
                sumL += tier.liquidity;
                sumLTick += int256(TickMath.sqrtPToTick(tier.sqrtP)) * int256(uint256(tier.liquidity));
            }

            // accumulate tick * seconds elapsed
            Info memory twap = self;
            uint32 timestamp = uint32(block.timestamp);
            uint32 secs = timestamp - twap.lastUpdate;
            int56 tickCumulative = twap.tickCumulative + int56((sumLTick * int256(uint256(secs))) / int256(sumL));

            // calculate EMA
            (uint256 d60, uint256 d30, uint256 d15) = EMAMath.calcDecayFactors(secs);
            int24 ema15 = int24(((sumLTick * int256(Q64 - d15)) / int256(sumL) + twap.tickEma15 * int256(d15)) >> 64);
            int24 ema30 = int24(((sumLTick * int256(Q64 - d30)) / int256(sumL) + twap.tickEma30 * int256(d30)) >> 64);
            int24 ema60 = int24(((sumLTick * int256(Q64 - d60)) / int256(sumL) + twap.tickEma60 * int256(d60)) >> 64);

            // effects
            self.lastUpdate = timestamp;
            self.tickCumulative = tickCumulative;
            self.tickEma15 = ema15;
            self.tickEma30 = ema30;
            self.tickEma60 = ema60;
        }
    }
}
