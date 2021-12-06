// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

library UnsafeMath {
    /// @dev Division by 0 has unspecified behavior, and must be checked externally.
    function ceilDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

library Math {
    /// @dev Compute z = x + y, where z must be non-negative and fit in a 128-bit unsigned integer
    function addInt128(uint128 x, int128 y) internal pure returns (uint128 z) {
        unchecked {
            int256 s = int256(uint256(x)) + y; // won't overflow
            assert(s >= 0 && s <= int256(uint256(type(uint128).max)));
            z = uint128(uint256(s));
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // ----- cast -----

    function abs256(int256 x) internal pure returns (uint256 z) {
        unchecked {
            z = x < 0 ? uint256(-x) : uint256(x);
        }
    }

    function toUint128(uint256 y) internal pure returns (uint128 z) {
        assert((z = uint128(y)) == y);
    }

    function toInt256(uint256 x) internal pure returns (int256 z) {
        assert(x <= uint256(type(int256).max));
        z = int256(x);
    }

    function toInt128(uint128 x) internal pure returns (int128 z) {
        assert(x <= uint128(type(int128).max));
        z = int128(x);
    }

    // ----- checked arithmetic -----
    // (these functions are for using checked arithmetic in an unchecked scope)

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
    }
}
