// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @dev Each tier represent a swap fee of the pool. Note that, however, the swap fee of the tier is not
 * stored inside the `Tier` struct, but stored inside a SqrtGammaMap for gas optimization.
 */
library Tiers {
    struct Tier {
        uint128 liquidity;
        uint128 sqrtP; //   UQ56.72
    }
}
