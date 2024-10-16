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
import {IVault} from "./interfaces/IVault.sol";

import {ILemonJetToken} from "./interfaces/ILemonJetToken.sol";

contract LemonJet is ILemonJet, VRFV2PlusWrapperConsumerBase {
    using SafeERC20 for IERC20;

    uint256 public constant houseEdge = 1; // %

    address public immutable ljtVault;
    address public immutable usdcVault;
    address public immutable treasury;

    mapping(uint256 => JetGame) public ljtGames;
    mapping(uint256 => JetGame) public usdcGames;
    // referee => referral
    mapping(address => address) private referrals;

    struct JetGame {
        uint256 wager;
        address player;
        uint16 multiplier;
    }

    constructor(address wrapperAddress, address _ljtVault, address _usdcVault, address _treasury)
        VRFV2PlusWrapperConsumerBase(wrapperAddress)
    {
        IERC20(IVault(_ljtVault).asset()).approve(address(_ljtVault), type(uint256).max);
        IERC20(IVault(_usdcVault).asset()).approve(address(_ljtVault), type(uint256).max);
        treasury = _treasury;
        ljtVault = _ljtVault;
        usdcVault = _usdcVault;
    }

    function playLjt(uint256 wager, address referral, uint16 multiplier) public payable returns (uint256) {
        (JetGame memory game, uint256 _requestId) = _play(wager, multiplier, referral, IVault(ljtVault));

        ljtGames[_requestId] = game;
        return _requestId;
    }

    function playUsdc(uint256 wager, address referral, uint16 multiplier) public payable returns (uint256) {
        (JetGame memory game, uint256 _requestId) = _play(wager, multiplier, referral, IVault(usdcVault));
        usdcGames[_requestId] = game;
        return _requestId;
    }

    function _play(uint256 wager, uint16 multiplier, address referrer, IVault vault)
        private
        returns (JetGame memory game, uint256 requestId)
    {
        require(multiplier >= 1_01 && multiplier <= 5000_00, InvalidMultiplier());
        uint256 _maxWinAmount = vault.maxWinAmount();
        require((wager * multiplier) / 100 <= _maxWinAmount, WagerAboveLimit());
        address asset = vault.asset();
        IERC20(asset).safeTransferFrom(msg.sender, address(this), wager);
        _setReferralIfNotExists(msg.sender, referrer);
        (requestId,) = _requestRandomWord();
        game = JetGame(wager, msg.sender, multiplier);

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
        JetGame memory game = ljtGames[requestId];
        IVault vault;
        if (game.player == address(0)) {
            game = usdcGames[requestId];
            delete usdcGames[requestId];
            vault = IVault(usdcVault);
        } else {
            delete ljtGames[requestId];
            vault = IVault(ljtVault);
        }

        address playerAddress = game.player;

        uint256 randomNumber = (randomWords[0] % 1000_00);

        (uint256 payout, uint256 threshold) = calculateWinnings(game.wager, randomNumber, game.multiplier, houseEdge);

        // При победе
        if (payout != 0) {
            _payoutWin(vault, playerAddress, payout);
        }

        uint256 fee = game.wager / 100; // 1% fee
        address referral = referrals[playerAddress];
        if (referral != address(0)) {
            uint256 referralReward = (fee * 30) / 100; // 30% of fee
            // Send fee to referree
            fee -= referralReward;
            vault.deposit(referralReward, referral);
            // IERC20(vault.asset()).safeTransfer(referral, fee);
            // emit SentToReferree(refReward);
        }

        uint256 treasuryCommission = (fee * 20) / 100; // 20% of fee
        fee -= treasuryCommission;
        vault.deposit(treasuryCommission, treasury);
        IERC20(vault.asset()).safeTransfer(address(vault), fee);

        emit OutcomeEvent(
            requestId,
            playerAddress,
            game.wager,
            payout,
            randomNumber,
            (1000_00_00 * (100 - houseEdge)) / 100 / randomNumber,
            threshold,
            game.multiplier
        );

        // delete (games[requestId]);
    }

    function _requestRandomWord() private returns (uint256 s_requestId, uint256 requestPrice) {
        //TODO: use yul

        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}));
        return requestRandomnessPayInNative(100000, 0, 1, extraArgs);

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

    function _payoutWin(IVault vault, address to, uint256 amount) private {
        vault.payoutWin(to, amount);
    }

    function _setReferralIfNotExists(address referee, address referral) private {
        if (referrals[referee] != address(0)) return;
        referrals[referee] = referral;
    }
}
