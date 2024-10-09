// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4626Fees} from "./ERC4626Fees.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is Ownable, ERC4626Fees {
    address public paymentContract;
    uint8 public immutable MAX_PAYOUT_PERCENT;

    using Math for uint256;

    event PayWin(address indexed receiver, uint256 assets);

    error ExceededMaxWinAmount(uint256 maxWinAmount, uint256 recivedWinAmount);

    error NotPaymentContract();

    constructor(
        ERC20 _asset,
        address _paymentContract,
        address _initialOwner,
        uint8 _maxPayoutPercent,
        string memory _name,
        string memory _symbol
    ) Ownable(_initialOwner) ERC20(_name, _symbol) ERC4626(_asset) {
        MAX_PAYOUT_PERCENT = _maxPayoutPercent;
        paymentContract = _paymentContract;
    }

    function maxWinAmount() public view returns (uint256) {
        return
            totalAssets().mulDiv(MAX_PAYOUT_PERCENT, 100, Math.Rounding.Ceil);
    }

    function payoutWin(address receiver, uint256 assets) external {
        if (msg.sender != paymentContract) {
            revert NotPaymentContract();
        }
        uint256 _maxWinAmount = maxWinAmount();
        if (assets > _maxWinAmount) {
            revert ExceededMaxWinAmount(_maxWinAmount, assets);
        }

        ERC20(asset()).transfer(receiver, assets);

        emit PayWin(receiver, assets);
    }

    function setPaymentContract(address _paymentContract) external onlyOwner {
        paymentContract = _paymentContract;
    }
}
