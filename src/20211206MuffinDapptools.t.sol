// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./20211206MuffinDapptools.sol";

contract 20211206MuffinDapptoolsTest is DSTest {
    20211206MuffinDapptools dapptools;

    function setUp() public {
        dapptools = new 20211206MuffinDapptools();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
