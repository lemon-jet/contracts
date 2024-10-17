// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IVault} from "./interfaces/IVault.sol";
import {ERC4626Fees} from "./ERC4626Fees.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is IVault, ERC4626Fees {
    uint256 public constant MAX_PAYOUT_PERCENT = 1;

    using Math for uint256;
    using SafeERC20 for IERC20;

    constructor(address _asset, address _reserveFund, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC4626Fees(_reserveFund)
        ERC4626(IERC20(_asset))
    {}

    function maxWinAmount() public view returns (uint256) {
        return totalAssets().mulDiv(MAX_PAYOUT_PERCENT, 100, Math.Rounding.Ceil);
    }

    function _mintSharesByAssets(address receiver, uint256 assets) internal {
        uint256 shares = previewDeposit(assets);
        _mint(receiver, shares);
    }

    function _payoutWin(address receiver, uint256 assets) internal {
        IERC20(asset()).safeTransfer(receiver, assets);
        emit PayoutWin(receiver, assets);
    }
}
