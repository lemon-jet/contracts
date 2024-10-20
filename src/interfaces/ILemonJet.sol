// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface ILemonJet {
    event PlayEvent(
        uint256 requestId,
        address player,
        uint256 wager,
        uint256 multiplier
    );

    event RefundEvent(address player, uint256 wager);

    event SentToReferree(uint256 referreeReward);

    event OutcomeEvent(
        uint256 requestId,
        address indexed playerAddress,
        uint256 payout,
        uint256 randomNumber,
        uint256 x
    );

    event TransferPayoutFailed(address player, uint256 payout);

    error WagerAboveLimit(uint256);
    error WagerBelowLimit(uint256);
    error InvalidMultiplier();
    error AlreadyInGame();
    error InvalidReferrer();
    error NotTreasury();
    error WithdrawFailed();
}
