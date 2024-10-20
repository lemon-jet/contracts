// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {Referral} from "../src/Referral.sol";

contract LemonJetDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address reserveFund = vm.envAddress("RESERVE_FUND_ADDRESS");
        address vrfWrapper = vm.envAddress("VRF_WRAPPER_ADDRESS");
        address vaultToken = vm.envAddress("VAULT_TOKEN_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        Referral referral = new Referral();
        ERC20Mock asset = new ERC20Mock();

        LemonJet lemonJet =
            new LemonJet(vrfWrapper, reserveFund, address(asset), address(referral), "LemonJet Vault", "LJUSDC");
        console2.log(address(lemonJet));
        vm.stopBroadcast();
    }
}
