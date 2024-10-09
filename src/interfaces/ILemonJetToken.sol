// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ILemonJetToken {
    function transferWager(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transferReward(address to, uint256 amount) external returns (bool);
}
