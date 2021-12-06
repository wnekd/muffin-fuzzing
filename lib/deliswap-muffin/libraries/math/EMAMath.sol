// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library EMAMath {
    uint256 private constant Q64 = 0x10000000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /**
     *  Definition:
     *  EMA[T] = a * P[T] + (1-a) * EMA[T-1]
     *  -   EMA[T]: EMA price at time T
     *  -   P[T]:   price at time T
     *  -   a:      smoothing factor, 0 < a ≤ 1
     *
     *  For 1-second sampling interval,
     *  -   Using common convention of EMA period:  a = 2/(N+1)
     *  -   Using half-life:                        a = 1 - 2^(-1/H)
     *  -   Combining both formula:             =>  a = 1 - (N+1)/(N-1)
     *
     *  For t-second interval,
     *  -   a = 1 - ((N-1)/(N+1))^t
     *
     *  We want to calculate the decay factor (i.e. 1-a) for a 60-min EMA.
     *  Let N = 3600 sec,
     *      u = (N-1)/(N+1) = 0.99944459872
     *      t = seconds elapsed since last EMA update
     *  Find d = u^t
     */

    /// @param t The seconds elapsed
    /// @return d60 The decay factor for 60-min EMA (UQ1.64)
    /// @return d30 The decay factor for 30-min EMA (UQ1.64)
    /// @return d15 The decay factor for 15-min EMA (UQ1.64)
    function calcDecayFactors(uint256 t)
        internal
        pure
        returns (
            uint256 d60,
            uint256 d30,
            uint256 d15
        )
    {
        unchecked {
            if (t == 0) return (Q64, Q64, Q64);
            if (t > 0x3FFF) return (0, 0, 0);

            uint256 r = Q128;
            if (t & 0x1 > 0) r = (r * 0xffdb99e9ad644f5684a80f5b116ad9af) >> 128;
            if (t & 0x2 > 0) r = (r * 0xffb7390039c5a63d172c56b91242c43c) >> 128;
            if (t & 0x4 > 0) r = (r * 0xff6e86b0fe1b737b7092471ae7e23a03) >> 128;
            if (t & 0x8 > 0) r = (r * 0xfedd600ca132d40a4736a70b242a0c58) >> 128;
            if (t & 0x10 > 0) r = (r * 0xfdbc0a0809b8a80c205bf702a09f7b15) >> 128;
            if (t & 0x20 > 0) r = (r * 0xfb7d35f29f69e461d2cf419a0c67aed7) >> 128;
            if (t & 0x40 > 0) r = (r * 0xf70ec5077ee7af347af348c52da004e1) >> 128;
            if (t & 0x80 > 0) r = (r * 0xee6d810e9b597ef7323a2546ec8f6376) >> 128;
            if (t & 0x100 > 0) r = (r * 0xde0fcace505a6baf4de9658493d936ea) >> 128;
            if (t & 0x200 > 0) r = (r * 0xc09f64b738347a70c65a85bf030b541d) >> 128;
            if (t & 0x400 > 0) r = (r * 0x90ef7a5117862fe3a8a4559644e715bc) >> 128;
            if (t & 0x800 > 0) r = (r * 0x520e49a0d8524689538670df4941787d) >> 128;
            if (t & 0x1000 > 0) r = (r * 0x1a4d27f72d597e9dba64b1c77822272e) >> 128;
            if (t & 0x2000 > 0) r = (r * 0x2b3c35f4624b408040d8da48eb1af32) >> 128;
            // stop here since t < 0x4000

            d60 = r >> 64; // UQ0.64
            d30 = (r * r) >> 192; // UQ0.64
            d15 = (d60 * d60 * d60 * d60) >> 192; // UQ0.64
        }
    }
}
