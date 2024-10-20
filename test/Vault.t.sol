// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {Vault} from "../src/Vault.sol";
import {HelperContract} from "./HelperContract.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract VaultTest is Test, HelperContract {
    ERC20Mock asset;
    Vault vault;

    function setUp() public {
        asset = new ERC20Mock();
        vault = new Vault(
            address(asset),
            reserveFund,
            "LemonJet Vault",
            "VLJT"
        );
        asset.mint(player, 1 ether);
        vm.startPrank(player);
        asset.approve(address(vault), type(uint256).max);
    }

    function testDepositAndWithdraw() public {
        uint256 beforeDepositBalance = asset.balanceOf(player);

        vault.deposit(1 ether, player);
        console2.log(vault.balanceOf(player));
        vault.withdraw(
            vault.previewRedeem(vault.balanceOf(player)),
            player,
            player
        );

        console2.log(asset.balanceOf(address(vault)));

        uint256 afterWithdrawBalance = asset.balanceOf(player);
        console2.log(
            "beforeDepositBalance - afterWithdrawBalance",
            beforeDepositBalance - afterWithdrawBalance
        );

        console2.log(
            "reserveFund Balance in shares",
            vault.balanceOf(reserveFund)
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
