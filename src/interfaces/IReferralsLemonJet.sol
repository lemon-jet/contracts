// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IReferralsLemonJet {
    function setReferral(address referral) external;

    function referrals(address player) external view returns (address);
}
