// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ILemonJet} from "./interfaces/ILemonJet.sol";
import {Vault} from "./Vault.sol";
import {IReferral} from "./interfaces/IReferral.sol";

import {ILemonJetToken} from "./interfaces/ILemonJetToken.sol";

contract LemonJet is ILemonJet, Vault, VRFV2PlusWrapperConsumerBase {
    using SafeERC20 for IERC20;

    uint8 private constant STARTED = 1;
    uint8 private constant RELEASED = 2;

    uint256 public constant houseEdge = 1; // %
    uint256 public constant threshold = 1e7; // 1000_00_00
    IReferral public immutable referrals;

    mapping(address => JetGame) public games;
    mapping(uint256 => address) public requestIdToPlayer;

    struct JetGame {
        uint224 potentialWinnings;
        uint24 threshold; // always less than threshold (1000_00_00)
        uint8 status; // 0, 1, 2
    }

    constructor(
        address wrapperAddress,
        address _reserveFund,
        address _asset,
        address _referral,
        string memory _name,
        string memory _symbol
    )
        VRFV2PlusWrapperConsumerBase(wrapperAddress)
        Vault(_asset, _reserveFund, _name, _symbol)
    {
        referrals = IReferral(_referral);
    }

    function play(
        uint256 wager,
        address referral,
        uint16 multiplier
    ) external payable {
        address _referral = _setReferralIfNotExists(referral);
        _play(wager, _referral, multiplier);
    }

    function play(uint256 wager, uint16 multiplier) external payable {
        address referral = referrals.getReferral(tx.origin);
        _play(wager, referral, multiplier);
    }

    function _play(uint256 wager, address referral, uint16 multiplier) private {
        require(wager >= 1000, WagerBelowLimit(1000));
        require(
            multiplier >= 1_01 && multiplier <= 5000_00,
            InvalidMultiplier()
        );
        uint256 potentialWinnings = (wager * multiplier) / 100;
        uint256 _maxWinAmount = maxWinAmount();
        require(
            potentialWinnings <= maxWinAmount(),
            WagerAboveLimit(_maxWinAmount)
        );
        require(games[msg.sender].status != STARTED, AlreadyInGame());
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), wager);
        uint256 requestId = _requestRandomWord();
        requestIdToPlayer[requestId] = msg.sender;
        games[msg.sender] = JetGame(
            uint224(potentialWinnings),
            uint24(calcThresholdForMultiplier(multiplier)),
            STARTED
        );

        uint256 fee = wager / 100; // 1% fee
        if (referral != address(0)) {
            uint256 referralReward = (fee * 30) / 100; // 30% of fee
            _mintByAssets(referral, referralReward);
        }

        uint256 reserveFundFee = (fee * 20) / 100; // 20% of fee
        _mintByAssets(reserveFund, reserveFundFee);

        emit PlayEvent(requestId, msg.sender, wager, multiplier);
    }

    function calcThresholdForMultiplier(
        uint256 multiplier
    ) public pure returns (uint256) {
        uint256 baseThreshold = threshold / multiplier;
        uint256 adjustedThreshold = (baseThreshold * (100 - houseEdge)) / 100;
        return adjustedThreshold;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _releaseGame(requestId, randomWords[0]);
    }

    function _releaseGame(uint256 requestId, uint256 randomNumber) private {
        address player = requestIdToPlayer[requestId];
        JetGame storage game = games[player];

        randomNumber = (randomNumber % 1000_00) + 1;

        // check if a player has won
        if (randomNumber <= game.threshold) {
            _payoutWin(player, game.potentialWinnings);
        }

        emit OutcomeEvent(
            requestId,
            player,
            game.potentialWinnings,
            randomNumber,
            (threshold * (100 - houseEdge)) / 100 / randomNumber
        );

        game.status = RELEASED;
        delete requestIdToPlayer[requestId];
    }

    function _requestRandomWord() private returns (uint256 requestId) {
        // // implimentation of the https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol#L21

        bytes memory extraArgs;
        assembly {
            extraArgs := mload(0x40)
            mstore(extraArgs, 0x24) //  36 bytes length selector (4 bytes) + bool (32 bytes)
            mstore(add(extraArgs, 0x04), 0x92fd1338) // EXTRA_ARGS_V1_TAG
            mstore(add(extraArgs, 0x24), 1) // ExtraArgsV1
            mstore(0x40, add(extraArgs, 0x60)) // update free pointer
        }

        // foundry gas report estimate the `rawFulfillRandomWords` at 47738
        // zero block confirmations need to get a random number as fast as possible because
        (requestId, ) = requestRandomnessPayInNative(50_000, 0, 1, extraArgs);
    }

    function _setReferralIfNotExists(
        address referral
    ) private returns (address) {
        address _referral = referrals.getReferral(tx.origin);
        if (referral != address(0) && _referral == address(0)) {
            referrals.setReferral(referral);
            return referral;
        } else {
            return _referral;
        }
    }
}
