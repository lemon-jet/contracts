// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {Asset} from "../test/Asset.sol";
import {LemonJetToken} from "../test/mocks/LemonJetToken.sol";

contract LemonJetDeployScript is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address treasury = vm.envAddress("TREASURY_ADDRESS");
        // address vrfWrapper = vm.envAddress("VRF_WRAPPER_ADDRESS");
        // vm.startBroadcast(deployerPrivateKey);
        // LemonJetToken ljtToken = new LemonJetToken("LemonJetToken", "LJT");
        // LemonJet ljtGame = new LemonJet(vrfWrapper, address(ljtToken), treasury);
        // ljtToken.mint(address(ljtGame), 1000_000_000 * 1 ether);
        // ljtToken.setLj(address(ljtGame));
        // vm.stopBroadcast();
    }
}
