// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IReferralsLemonJet {
    error ZeroAddressNotAllowed();

    error ReferralAlreadySet();

    event ReferralSet(address indexed referee, address indexed referral);

    function setReferral(address referral) external;

    function referrals(address referee) external view returns (address);
}
