// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;
import {IReferralsLemonJet} from "./interfaces/IReferralsLemonJet.sol";

contract ReferralsLemonJet is IReferralsLemonJet {
    // referee => referral
    mapping(address => address) public referrals;

    function setReferral(address referral) external {
        referrals[tx.origin] = referral;
    }
}
