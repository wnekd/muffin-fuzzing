// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @dev Constants shared accross contracts and libraries
 */
library Constants {
    /// @dev Minimum tick spacing allowed
    int24 internal constant MIN_TICK_SPACING = 1;

    /// @dev Minimum tick, given min_tick_spacing = 1
    int24 internal constant MIN_TICK = -776363;

    /// @dev Maximum tick, given min_tick_spacing = 1
    int24 internal constant MAX_TICK = 776363;

    /// @dev Minimum sqrt price, i.e. TickMath.tickToSqrtP(MIN_TICK)
    uint128 internal constant MIN_SQRT_P = 65539;

    /// @dev Maximum sqrt price, i.e. TickMath.tickToSqrtP(MAX_TICK)
    uint128 internal constant MAX_SQRT_P = 340271175397327323250730767849398346765;

    /// @dev Maximum liquidityNet of a tick, i.e. type(uint128).max / ((MAX_TICK - MIN_TICK) / MIN_TICK_SPACING)
    int128 internal constant MAX_LIQUIDITY_NET = 219151586900031598275146167084062;

    /// @dev Base liquidity of a tier. User pays it when adding a new tier.
    uint128 internal constant BASE_LIQUIDITY = 10000;
}
