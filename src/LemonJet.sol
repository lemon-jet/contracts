// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VRFV2PlusWrapperConsumerBase} from
    "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILemonJet} from "./interfaces/ILemonJet.sol";
import {Vault} from "./Vault.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IReferralsLemonJet} from "./interfaces/IReferralsLemonJet.sol";

import {ILemonJetToken} from "./interfaces/ILemonJetToken.sol";

contract LemonJet is ILemonJet, Vault, VRFV2PlusWrapperConsumerBase {
    using SafeERC20 for IERC20;

    uint8 private constant RELEASED = 1;
    uint8 private constant STARTED = 2;

    uint256 public constant houseEdge = 1; // %
    IReferralsLemonJet public immutable referrals;

    mapping(address => JetGame) public games;
    mapping(uint256 => address) public requestIdToPlayer;

    struct JetGame {
        uint256 wager;
        uint16 multiplier;
        uint8 status;
    }

    constructor(
        address wrapperAddress,
        address _reserveFund,
        address _asset,
        address _referrals,
        string memory _name,
        string memory _symbol
    ) VRFV2PlusWrapperConsumerBase(wrapperAddress) Vault(_asset, _reserveFund, _name, _symbol) {
        reserveFund = _reserveFund;
        referrals = IReferralsLemonJet(_referrals);
    }

    function play(uint256 wager, address referrer, uint16 multiplier) external payable {
        require(multiplier >= 1_01 && multiplier <= 5000_00, InvalidMultiplier());
        require((wager * multiplier) / 100 <= maxWinAmount(), WagerAboveLimit());
        require(games[msg.sender].status != STARTED, AlreadyInGame());
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), wager);
        uint256 requestId = _requestRandomWord();
        requestIdToPlayer[requestId] = msg.sender;
        games[msg.sender] = JetGame(wager, multiplier, STARTED);
        _setReferralIfNotExists(referrer);
        emit PlayEvent(requestId, msg.sender, wager, multiplier);
    }

    function calculateWinnings(uint256 bet, uint256 random_number, uint256 win_multiplier, uint256 commission_rate)
        public
        pure
        returns (uint256, uint256)
    {
        // Рассчитываем порог выигрыша как обратную величину коэффициента выигрыша, затем корректируем с учетом комиссии
        uint256 base_threshold = 1000_00_00 / win_multiplier;
        uint256 adjusted_threshold = (base_threshold * (100 - commission_rate)) / 100; // Уменьшаем порог на комиссию

        // Проверяем, находится ли случайное число в пределах скорректированного порога для выигрыша
        if (random_number <= adjusted_threshold) {
            //todo maybe <, not <=
            // Рассчитываем выигрыш на основе фактической ставки
            uint256 winnings = (bet * win_multiplier) / 100;
            return (winnings, adjusted_threshold);
        } else {
            // В случае проигрыша возвращаем 0
            return (0, adjusted_threshold);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _releaseGame(requestId, randomWords[0]);
    }

    function _releaseGame(uint256 requestId, uint256 randomNumber) private {
        address player = requestIdToPlayer[requestId];
        JetGame storage game = games[player];

        randomNumber = randomNumber % 1000_00;

        (uint256 payout, uint256 threshold) = calculateWinnings(game.wager, randomNumber, game.multiplier, houseEdge);

        // При победе
        if (payout != 0) {
            _payoutWin(player, payout);
        }

        uint256 fee = game.wager / 100; // 1% fee

        address referral = referrals.referrals(player);
        if (referral != address(0)) {
            uint256 referralReward = (fee * 30) / 100; // 30% of fee
            _mintSharesByAssets(referral, referralReward);
        }

        uint256 reserveFundFee = (fee * 20) / 100; // 20% of fee
        _mintSharesByAssets(reserveFund, reserveFundFee);

        emit OutcomeEvent(
            requestId,
            player,
            game.wager,
            payout,
            randomNumber,
            (1000_00_00 * (100 - houseEdge)) / 100 / randomNumber,
            threshold,
            game.multiplier
        );

        game.status = RELEASED;
        delete requestIdToPlayer[requestId];
    }

    function _requestRandomWord() private returns (uint256 requestId) {
        //TODO: use yul

        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}));
        (requestId,) = requestRandomnessPayInNative(100000, 0, 1, extraArgs);

        // assembly {
        //     let ptr := mload(0x40)
        //     mstore(ptr, 0x92fd1338)
        //     ptr := add(ptr, 0x20)
        //     mstore(ptr, 1)
        //     let res := call(gas(), link_contract_addr, amount_wei,
        //         sub(ptr, 4), 0x24, 0, 0)
        //     let ret_size := returndatasize()
        //     if ret_size { returndatacopy(ptr, 0, ret_size) }
        //     if iszero(res) { revert(ptr, ret_size) }
        // }
    }

    function _setReferralIfNotExists(address referral) private {
        if (referral != address(0) && referrals.referrals(tx.origin) == address(0)) {
            referrals.setReferral(referral);
        }
    }
}
