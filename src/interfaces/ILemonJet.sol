// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface ILemonJet {
    event GameStarted(uint256 indexed requestId, address indexed player, uint256 bet, uint256 coef);

    event GameReleased(
        uint256 indexed requestId, address indexed playerAddress, uint256 payout, uint256 randomNumber, uint256 x
    );

    event ReferralRewardIssued(address indexed referral, address indexed player, uint256 rewardAmount);

    error BetAmountAboveLimit(uint256);
    error BetAmountBelowLimit(uint256);
    error InvalidMultiplier();
    error AlreadyInGame();
    error InvalidReferrer();
    error NotTreasury();
    error WithdrawFailed();
}
