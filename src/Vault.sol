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
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

contract Vault is IVault, ERC4626Fees {
    uint256 private constant _reserveFundFeeBasisPoints = 10; // 0.1%
    uint256 private constant _maxPayoutPercentBasicPoints = 100; // 1%;
    address public immutable reserveFund;

    using SafeERC20 for IERC20;

    constructor(
        address _asset,
        address _reserveFund,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC4626(IERC20(_asset)) {
        reserveFund = _reserveFund;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626Fees) returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);
        _mint(reserveFund, _reserveFundFee(shares));
        return shares;
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626Fees) returns (uint256) {
        uint256 assets = super.redeem(shares, receiver, owner);
        _mint(reserveFund, _reserveFundFee(shares));
        return assets;
    }

    function maxWinAmount() public view returns (uint256) {
        return
            (totalAssets() * _maxPayoutPercentBasicPoints) / _BASIS_POINT_SCALE;
    }

    function _mintByAssets(address receiver, uint256 assets) internal {
        _mint(receiver, convertToShares(assets));
    }

    function _payoutWin(address receiver, uint256 assets) internal {
        IERC20(asset()).safeTransfer(receiver, assets);
        emit PayoutWin(receiver, assets);
    }

    function _reserveFundFee(uint256 shares) private pure returns (uint256) {
        return
            (((shares * _BASIS_POINT_SCALE) /
                (_exitFeeBasisPoints + _BASIS_POINT_SCALE)) *
                _reserveFundFeeBasisPoints) / _BASIS_POINT_SCALE;
    }
}
