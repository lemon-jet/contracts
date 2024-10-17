// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
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

    uint256 public constant houseEdge = 1; // %
    address public immutable treasury;
    address public immutable referrals;

    mapping(address => JetGame) public games;

    mapping(uint256 => address) public requestIdToPlayer;

    struct JetGame {
        uint256 wager;
        uint16 multiplier;
    }

    constructor(
        address wrapperAddress,
        address _treasury,
        address _asset,
        address _referrals,
        string memory _name,
        string memory _symbol
    )
        Vault(_asset, _name, _symbol)
        VRFV2PlusWrapperConsumerBase(wrapperAddress)
    {
        treasury = _treasury;
        referrals = _referrals;
    }

    function play(
        uint256 wager,
        address referrer,
        uint16 multiplier
    ) external payable {
        require(
            multiplier >= 1_01 && multiplier <= 5000_00,
            InvalidMultiplier()
        );
        uint256 _maxWinAmount = maxWinAmount();
        require((wager * multiplier) / 100 <= _maxWinAmount, WagerAboveLimit());
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), wager);
        _setReferralIfNotExists(referrer);
        (uint256 requestId, ) = _requestRandomWord();
        games[msg.sender] = JetGame(wager, multiplier);
        emit PlayEvent(requestId, msg.sender, wager, multiplier);
    }

    function calculateWinnings(
        uint256 bet,
        uint256 random_number,
        uint256 win_multiplier,
        uint256 commission_rate
    ) public pure returns (uint256, uint256) {
        // Рассчитываем порог выигрыша как обратную величину коэффициента выигрыша, затем корректируем с учетом комиссии
        uint256 base_threshold = 1000_00_00 / win_multiplier;
        uint256 adjusted_threshold = (base_threshold *
            (100 - commission_rate)) / 100; // Уменьшаем порог на комиссию

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

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address player = requestIdToPlayer[requestId];
        JetGame memory game = games[player];

        uint256 randomNumber = (randomWords[0] % 1000_00);

        (uint256 payout, uint256 threshold) = calculateWinnings(
            game.wager,
            randomNumber,
            game.multiplier,
            houseEdge
        );

        // При победе
        if (payout != 0) {
            _payoutWin(player, payout);
        }

        uint256 fee = game.wager / 100; // 1% fee

        address referral = IReferralsLemonJet(referrals).referrals(player);
        if (referral != address(0)) {
            uint256 referralReward = (fee * 30) / 100; // 30% of fee
            // Send fee to referree
            fee -= referralReward;
            _mint(referral, referralReward);
            // IERC20(vault.asset()).safeTransfer(referral, fee);
            // emit SentToReferree(refReward);
        }

        uint256 treasuryCommission = (fee * 20) / 100; // 20% of fee
        fee -= treasuryCommission;
        _mint(treasury, treasuryCommission);
        delete requestIdToPlayer[requestId];

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

        // delete (games[requestId]);
    }

    function _requestRandomWord()
        private
        returns (uint256 s_requestId, uint256 requestPrice)
    {
        //TODO: use yul

        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        );
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

    function _payoutWin(address to, uint256 amount) private {
        IERC20(asset()).safeTransfer(to, amount);
    }

    function _setReferralIfNotExists(address referral) private {
        IReferralsLemonJet _referrals = IReferralsLemonJet(referrals);

        if (_referrals.referrals(tx.origin) != address(0)) return;
        _referrals.setReferral(referral);
    }
}
