// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4626Fees} from "./ERC4626Fees.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is ERC4626Fees {
    uint8 public immutable MAX_PAYOUT_PERCENT;
    address public immutable PAYMENT_CONTRACT;
    using Math for uint256;

    event PayWin(address indexed receiver, uint256 assets);

    error ExceededMaxWinAmount(uint maxWinAmount, uint recivedWinAmount);

    error NotPaymentContract();

    constructor(
        ERC20 _asset,
        address _paymentContract,
        uint8 _maxPayoutPercent,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC4626(_asset) {
        MAX_PAYOUT_PERCENT = _maxPayoutPercent;
        PAYMENT_CONTRACT = _paymentContract;
    }

    function maxWinAmount() public view returns (uint) {
        return
            totalAssets().mulDiv(MAX_PAYOUT_PERCENT, 100, Math.Rounding.Ceil);
    }

    function payoutWin(address receiver, uint256 assets) external {
        require(msg.sender == PAYMENT_CONTRACT, NotPaymentContract());
        uint _maxWinAmount = maxWinAmount();

        require(
            _maxWinAmount >= assets,
            ExceededMaxWinAmount(_maxWinAmount, assets)
        );

        ERC20(asset()).transfer(receiver, assets);

        emit PayWin(receiver, assets);
    }
}
