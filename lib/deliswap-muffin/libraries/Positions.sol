// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/IRewarder.sol";
import "./math/Math.sol";
import "./math/FullMath.sol";

library Positions {
    struct Position {
        uint128 liquidity;
        uint128 rewardUnclaimed;
        uint128 token0Unclaimed;
        uint128 token1Unclaimed;
        uint256 feeGrowthInside0Last; //    UQ128.128
        uint256 feeGrowthInside1Last; //    UQ128.128
        uint208 rewardGrowthInsideLast; //  UQ120.88
        uint16 rewardId;
        bool rewardOptedOut;
    }

    uint256 private constant Q88 = 0x10000000000000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /// @param positions The mapping of positions
    /// @param owner The address of the position owner
    /// @param tierId The index of the tier of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param pid Any identifier set by the owner to distinguish this position from his/her others
    /// @return The identifier for the position
    function get(
        mapping(bytes32 => Position) storage positions,
        address owner,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 pid
    ) internal view returns (Position storage) {
        return positions[keccak256(abi.encode(owner, tierId, tickLower, tickUpper, pid))];
    }

    function update(
        Position storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0,
        uint256 feeGrowthInside1,
        uint208 rewardGrowthInside,
        uint16 rewardIdCurrent,
        IRewarder rewarder,
        IRewarder.PositionKey memory key
    ) internal {
        uint128 liquidity = self.liquidity;

        // accrue fee and reward. users need to collect them before overflow.
        unchecked {
            if (liquidity > 0) {
                uint256 feeAmt0 = FullMath.mulDiv(liquidity, feeGrowthInside0 - self.feeGrowthInside0Last, Q128);
                uint256 feeAmt1 = FullMath.mulDiv(liquidity, feeGrowthInside1 - self.feeGrowthInside1Last, Q128);
                self.token0Unclaimed += uint128(feeAmt0);
                self.token1Unclaimed += uint128(feeAmt1);
            }

            if (self.rewardId == rewardIdCurrent) {
                // LP can opt out reward accrual if the rewarder contract reverts tx and thus locks liquidity
                if (liquidity > 0 && !self.rewardOptedOut) {
                    uint128 multiplier = address(rewarder) != address(0) ? rewarder.getMultiplier(key) : 1e8;
                    self.rewardUnclaimed += uint128(
                        FullMath.mulDiv(
                            uint256(liquidity) * multiplier,
                            rewardGrowthInside - self.rewardGrowthInsideLast,
                            Q88 * 1e8
                        )
                    );
                }
            } else {
                // reset reward if position not in latest reward program. which means user need to
                // - collect reward before a new reward program is set
                // - update position to restart accrual after the new reward program is set
                self.rewardId = rewardIdCurrent;
                self.rewardUnclaimed = 0;
            }
        }

        // snapshot fee growth and reward growth
        self.feeGrowthInside0Last = feeGrowthInside0;
        self.feeGrowthInside1Last = feeGrowthInside1;
        self.rewardGrowthInsideLast = rewardGrowthInside;

        // update liquidity
        if (liquidityDelta != 0) self.liquidity = Math.addInt128(liquidity, liquidityDelta);
    }
}
