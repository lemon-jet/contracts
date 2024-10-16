// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {LemonJetEntropy} from "../src/LemonJetEntropy.sol";
import {Asset} from "../test/Asset.sol";
import {LemonJetToken} from "../test/mocks/LemonJetToken.sol";

contract LemonJetEntropyDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address entropyProvider = vm.envAddress("ENTROPY_PROVIDER");
        vm.startBroadcast(deployerPrivateKey);
        LemonJetToken ljtToken = new LemonJetToken("LemonJetToken", "LJT");
        LemonJetEntropy ljtGame = new LemonJetEntropy(entropyProvider, address(ljtToken), treasury);
        ljtToken.mint(address(ljtGame), 1000_000_000 * 1 ether);
        ljtToken.mint(address(treasury), 1000_000_000 * 1 ether);
        ljtToken.setLj(address(ljtGame));
        vm.stopBroadcast();
    }
}
