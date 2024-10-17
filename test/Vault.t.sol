// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {Asset} from "./Asset.sol";
import {Vault} from "../src/Vault.sol";
import {HelperContract} from "./HelperContract.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract VaultTest is Test, HelperContract {
    Asset public asset;
    Vault vault;

    function setUp() public {
        asset = new Asset(address(this));
        vault = new Vault(address(asset), "LemonJet Vault", "VLJT");
        asset.approve(address(vault), type(uint256).max);
    }

    function testDepositAndWithdraw() public {
        asset.mint(address(this), 10 ether);
        uint256 beforeDepositBalance = asset.balanceOf(address(this));

        vault.deposit(1 ether, address(this));
        vault.redeem(
            vault.previewWithdraw(
                vault.previewRedeem(vault.balanceOf(address(this)))
            ),
            address(this),
            address(this)
        );

        uint256 afterWithdrawBalance = asset.balanceOf(address(this));
        // assertEq(beforeDepositBalance - afterWithdrawBalance <= Math.mulDiv(...), true);
        console2.log(
            "beforeDepositBalance - afterWithdrawBalance",
            beforeDepositBalance - afterWithdrawBalance
        );
    }

    function testDepositAndGreaterWithdraw() public {
        asset.mint(address(this), 10 ether);
        uint256 beforeDepositBalance = asset.balanceOf(address(this));
        vault.deposit(1 ether, address(this));

        asset.mint(address(vault), 10 ether);

        vault.withdraw(10 ether, address(this), address(this));
        uint256 afterWithdrawBalance = asset.balanceOf(address(this));
        assertEq(beforeDepositBalance < afterWithdrawBalance, true);
    }
}
