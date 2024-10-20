// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IReferral {
    error ZeroAddressNotAllowed();

    error ReferralAlreadySet();

    /**
     * @dev Emitted when `referee` aka `tx.origin` have set a `referral` address
     */
    event ReferralSettled(address indexed referee, address indexed referral);

    function setReferral(address referral) external;

    function getReferral(address referee) external view returns (address);
}
