// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Vault} from "../src/Vault.sol";
import {Asset} from "../test/Asset.sol";

contract VaultDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);
        Asset asset = new Asset(owner);
        Vault vault = new Vault(asset, owner, owner, 1, "Vault USDC", "VUSDC");
        vm.stopBroadcast();
    }
}
