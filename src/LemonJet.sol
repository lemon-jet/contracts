// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ILemonJet} from "./interfaces/ILemonJet.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILemonJetToken} from "./interfaces/ILemonJetToken.sol";

contract LemonJet is ILemonJet, Ownable, VRFV2PlusWrapperConsumerBase {
    error WagerAboveLimit();
    error InvalidMultiplier();
    error AlreadyAwaiting();
    error InvalidReferrer();
    error NotTreasury();
    error WithdrawFailed();

    using SafeERC20 for IERC20;

    uint256 public constant referreeReward = 30; // %
    uint256 public constant rake = 70; // %
    uint256 public constant houseEdge = 1; // %

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 100000;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 public numWords = 1;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    mapping(address => JetGame) public games;
    mapping(uint256 => address) public requestToPlayer;
    // referee => referral
    mapping(address => address) private referrals;

    address public immutable ljt;
    address public immutable treasury;

    struct JetGame {
        uint256 requestId;
        uint256 wager;
        uint256 multiplier;
        address player;
        uint64 blockNumber;
    }

    constructor(
        address _wrapperAddress,
        address _ljt,
        address _treasury
    ) Ownable(msg.sender) VRFV2PlusWrapperConsumerBase(_wrapperAddress) {
        treasury = _treasury;
        ljt = _ljt;
    }

    function play(
        uint256 wager,
        uint256 multiplier,
        address referrer
    ) external payable {
        uint256 maxWager = getMaxWager();
        if (wager > maxWager) {
            revert WagerAboveLimit();
        }
        if (multiplier < 1_01 || multiplier > 1000_00) {
            // 1.01x 100x
            revert InvalidMultiplier();
        }

        if (games[msg.sender].requestId != 0) {
            revert AlreadyAwaiting();
        }

        _setReferree(msg.sender, referrer);
        _transferWager(wager, msg.sender);
        (uint256 requestId, ) = _requestRandomWord();

        games[msg.sender] = JetGame(
            requestId,
            wager,
            multiplier,
            msg.sender,
            uint64(block.number)
        );

        requestToPlayer[requestId] = msg.sender;

        emit PlayEvent(
            requestId,
            msg.sender,
            wager,
            multiplier,
            uint64(block.number)
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address playerAddress = requestToPlayer[requestId];
        JetGame storage game = games[playerAddress];

        uint256 r = randomWords[0] % 1000_00;

        (uint256 payout, uint256 threshold) = calculateWinnings(
            game.wager,
            r,
            game.multiplier,
            houseEdge
        );

        // При победе
        if (payout != 0) {
            _transferPayout(playerAddress, payout);
        }

        uint256 fee = game.wager / 100;
        if (referrals[playerAddress] != address(0)) {
            uint256 refReward = (fee * referreeReward) / 100;
            // Send fee to referree
            fee -= refReward;
            _transferPayout(referrals[playerAddress], refReward);

            emit SentToReferree(refReward);
        }

        _transferPayout(treasury, fee);

        emit OutcomeEvent(
            requestId,
            playerAddress,
            game.wager,
            payout,
            r,
            Math.max((10000000 * (1_00 - houseEdge)) / 100 / r, 100),
            threshold,
            game.multiplier
        );

        delete (requestToPlayer[requestId]);
        delete (games[playerAddress]);
    }

    function calculateWinnings(
        uint256 bet,
        uint256 random_number,
        uint256 win_multiplier,
        uint256 commission_rate
    ) public pure returns (uint256, uint256) {
        // Рассчитываем порог выигрыша как обратную величину коэффициента выигрыша, затем корректируем с учетом комиссии
        uint256 base_threshold = 1000_0000 / win_multiplier;
        uint256 adjusted_threshold = (base_threshold *
            (1_00 - commission_rate)) / 100; // Уменьшаем порог на комиссию

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

    function _requestRandomWord()
        internal
        returns (uint256 s_requestId, uint256 requestPrice)
    {
        //TODO: use yul
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        );
        return
            requestRandomnessPayInNative(
                callbackGasLimit,
                requestConfirmations,
                1,
                extraArgs
            );
    }

    function _transferWager(uint256 wager, address msgSender) internal {
        ILemonJetToken(ljt).transferWager(msgSender, address(this), wager);
    }

    function _transferPayout(address to, uint256 amount) internal {
        ILemonJetToken(ljt).transferReward(to, amount);
    }

    function getMaxWager() public view returns (uint256) {
        uint256 balance = IERC20(ljt).balanceOf(address(this));
        uint256 maxWager = (balance * 1122448) / 100000000; // 1.122448% of bankroll size
        return maxWager;
    }

    function _setReferree(address referee, address referral) internal {
        if (referrals[referee] != address(0)) return;
        referrals[referee] = referral;
    }

    function withdraw(uint256 value) public {
        if (msg.sender != treasury) revert NotTreasury();
        (bool success, ) = payable(treasury).call{value: value}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function setCallbackGasLimit(uint32 limit) public onlyOwner {
        callbackGasLimit = limit;
    }

    receive() external payable {}
}
