// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {IReferral} from "./interfaces/IReferral.sol";

/// @title Referral contract
/// @notice set and stores who invited the player
/// @dev allowing the EOA or contract to set up only once a referral address for `tx.origin`
contract Referral is IReferral {
    // referee => referral
    mapping(address => address) private referrals;

    /// @dev `tx.origin` is used for new contracts so they can add referrals.
    function setReferral(address referral) external {
        require(referral != address(0), ZeroAddressNotAllowed());
        require(referrals[tx.origin] == address(0), ReferralAlreadySet());
        referrals[tx.origin] = referral;
        emit ReferralSettled(tx.origin, referral);
    }

    function getReferral(address referee) external view returns (address) {
        return referrals[referee];
    }
}
