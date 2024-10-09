pragma solidity 0.8.20;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/lib/chainlink-brownie-contracts/dev/vrf/libraris/VRFCoordinatorV2.sol";

import {ILemonJet} from "./ILemonJet.sol";

contract LemonJet is ILemonJet {
    using SafeERC20 for IERC20;

    address public constant ljt;
    address public constant tresuary;

    uint256 public constant referreeReward = 30; // %

    uint256 public constant rake = 70; // %

    uint256 public constant houseEdge = 1; // %

    bytes32 public constant keyHash;
    uint64 public constant subId;

    IVRFCoordinatorV2 public IChainLinkVRF;

    mapping(address => JetGame) public games;
    mapping(uint256 => address) public requestToPlayer;
    // referee => referral
    mapping(address => address) private referrals;

    struct JetGame {
        uint256 requestId;
        uint256 wager;
        uint256 multiplier;
        address player;
        uint64 blockNumber;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ChainLinkVRF,
        bytes32 _keyHash,
        uint64 _subId,
        address _tresuary
    ) public initializer {
        __Ownable_init();
        tresuary = _tresuary;
        subId = _subId;
        IChainLinkVRF = IVRFCoordinatorV2(_ChainLinkVRF);
        keyHash = _keyHash;
        referreeReward = 30; // %
        rake = 70; // %
        houseEdge = 1; // %
    } // https://docs.chain.link/vrf/v2/subscription/supported-networks#arbitrum-sepolia-testnet:~:text=ARBITRUM%20SEPOLIA%20TESTNET%20FAUCET

    function play(
        uint256 wager,
        uint256 multiplier,
        address referrer
    ) external nonReentrant {
        uint256 maxWager = getMaxWager();
        require(wager <= maxWager, "WagerAboveLimit");
        require(
            multiplier >= 1_01 && multiplier <= 1000_00,
            "Invalid Multiplier"
        ); // 1.01x 100x
        require(games[msg.sender].requestId == 0, "Already awaiting");

        _setReferree(msg.sender, referrer);
        _transferWager(wager, msg.sender);
        uint256 requestId = _requestRandomWords(1);

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

    /**
     * @dev function called by Chainlink VRF with random numbers
     * @param requestId id provided when the request was made
     * @param randomWords array of random numbers
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        require(
            msg.sender == address(IChainLinkVRF),
            "OnlyCoordinatorCanFulfill"
        );
        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        address playerAddress = requestToPlayer[requestId];
        require(playerAddress != address(0), "Zero address");
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

        _transferPayout(tresuary, fee);

        emit OutcomeEvent(
            requestId,
            playerAddress,
            game.wager,
            payout,
            r,
            (10000000 * ((1_00 - houseEdge) / 100)) / r,
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

    function _requestRandomWords(
        uint32 numWords
    ) internal returns (uint256 s_requestId) {
        s_requestId = VRFCoordinatorV2Interface(IChainLinkVRF)
            .requestRandomWords(keyHash, subId, 1, 2500000, numWords);
    }

    function _transferWager(uint256 wager, address msgSender) internal {
        require(wager != 0, "ZeroWager");
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
        require(msg.sender == tresuary, "Not tresuary");
        (bool s, ) = payable(tresuary).call{value: value}("");
        require(s, "Box: Withdraw went wrong");
    }

    function setLemonJetToken(address _ljt) public onlyOwner {
        require(_ljt != address(0), "Zero address");
        require(ljt == address(0), "Can't change lemon jet address");
        ljt = _ljt;
    }

    receive() external payable {}
}
