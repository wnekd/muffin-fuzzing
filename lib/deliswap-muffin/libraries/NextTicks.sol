// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./Constants.sol";

/**
 * @dev NextTicks stores all tiers' next upper and lower initialized ticks to cross.
 * @dev Each tick takes 21 bits and they are packed into two 128-bit data maps. Instead of storing
 * each of them inside `Tier` struct, packing them together in a 256-bit slot saves gas.
 */
library NextTicks {
    struct Info {
        uint128 below;
        uint128 above;
    }

    function _get(uint128 data, uint8 tierId) internal pure returns (int24 tick) {
        unchecked {
            tick = int24(int256((uint256(data) >> (uint256(tierId) * 21)) & 0x1FFFFF) + Constants.MIN_TICK);
        }
    }

    function _set(uint128 data, uint8 tierId, int24 tick) internal pure returns (uint128 ticks) {
        unchecked {
            uint256 start = uint256(tierId) * 21;
            ticks = uint128((data & ~(0x1FFFFF << start)) | (uint256(int256(tick) - Constants.MIN_TICK) << start));
        }
    }

    // ----- storage -----

    function getBelow(Info storage self, uint8 tierId) internal view returns (int24 tick) {
        tick = _get(self.below, tierId);
    }

    function getAbove(Info storage self, uint8 tierId) internal view returns (int24 tick) {
        tick = _get(self.above, tierId);
    }

    function setBelow(Info storage self, uint8 tierId, int24 tick) internal {
        self.below = _set(self.below, tierId, tick);
    }

    function setAbove(Info storage self, uint8 tierId, int24 tick) internal {
        self.above = _set(self.above, tierId, tick);
    }

    /// @dev Update nextTicks if the given tick is adjacent to the current tick. Used when initializing a tick.
    function insert(
        Info storage self,
        uint8 tierId,
        int24 tickNew,
        int24 tickCurrent
    ) internal {
        if (tickNew <= tickCurrent) {
            if (tickNew > _get(self.below, tierId)) self.below = _set(self.below, tierId, tickNew);
        } else {
            if (tickNew < _get(self.above, tierId)) self.above = _set(self.above, tierId, tickNew);
        }
    }

    // ----- memory -----

    function get(Info memory nextTicks, bool isBelow, uint8 tierId) internal pure returns (int24 tick) {
        tick = _get(isBelow ? nextTicks.below : nextTicks.above, tierId);
    }

    function set(
        Info memory nextTicks,
        uint8 tierId,
        int24 tickBelow,
        int24 tickAbove
    ) internal pure {
        nextTicks.below = _set(nextTicks.below, tierId, tickBelow);
        nextTicks.above = _set(nextTicks.above, tierId, tickAbove);
    }
}
