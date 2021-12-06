// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @dev SqrtGammaMap stores all tiers' gamma (i.e. 1 - percentage fee) (precision: 1e5). We store
 * sqrt(gamma) instead of gamma for calculation convenience.
 * @dev Each sqrtGamma takes 17 bits and they are packed into a uint104 slot. Instead of storing each of
 * them inside `Tier` struct, packing them together in a slot saves gas.
 */
library SqrtGammaMap {
    function get(uint104 data, uint8 tierId) internal pure returns (uint24 sqrtGamma) {
        unchecked {
            sqrtGamma = uint24((data >> (uint256(tierId) * 17)) & 0x1FFFF);
        }
    }

    function set(
        uint104 data,
        uint8 tierId,
        uint24 sqrtGamma
    ) internal pure returns (uint104 sqrtGammaMap) {
        unchecked {
            uint256 pos = uint256(tierId) * 17;
            sqrtGammaMap = uint104((data & ~(0x1FFFF << pos)) | (uint256(sqrtGamma) << pos));
        }
    }
}
