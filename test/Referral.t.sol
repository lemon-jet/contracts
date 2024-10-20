// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {HelperContract} from "./HelperContract.sol";
import {Referral} from "../src/Referral.sol";

contract ReferralTest is Test, HelperContract {
    Referral referral;

    function setUp() public {
        referral = new Referral();
    }

    function testSetReferralIfNotExists() public {}
}
