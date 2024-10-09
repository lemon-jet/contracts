// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ILemonJet {
    event PlayEvent(
        uint256 requestId,
        address player,
        uint256 wager,
        uint256 multiplier,
        uint64 blockNumber
    );

    event RefundEvent(address player, uint256 wager);

    event SentToReferree(uint referreeReward);

    event OutcomeEvent(
        uint256 requestId,
        address indexed playerAddress,
        uint wager,
        uint payout,
        uint randomNumber,
        uint x,
        uint threshold,
        uint multiplier
    );

    event TransferPayoutFailed(address player, uint payout);
}
