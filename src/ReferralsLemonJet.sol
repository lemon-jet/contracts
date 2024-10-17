// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {IReferralsLemonJet} from "./interfaces/IReferralsLemonJet.sol";

contract ReferralsLemonJet is IReferralsLemonJet {
    // referee => referral
    mapping(address => address) public referrals;

    function setReferral(address referral) external {
        require(referral != address(0), ZeroAddressNotAllowed());
        require(referrals[tx.origin] == address(0), ReferralAlreadySet());
        referrals[tx.origin] = referral;
        emit ReferralSet(tx.origin, referral);
    }
}
