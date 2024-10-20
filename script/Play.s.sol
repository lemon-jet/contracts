// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {LemonJetToken} from "../test/mocks/LemonJetToken.sol";

contract PlayLemonJetScript is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address payable ljtGame = payable(address(0x8938260E6418CF3b673C1E1bEcB61a77dFb1BB2f));
        // vm.startBroadcast(deployerPrivateKey);
        //
        // (bool success,) = ljtGame.call{value: 1000000000000000, gas: 500000}(
        //     abi.encodeWithSelector(
        //         LemonJet.play.selector, 111111, 200, address(0xBa0d95449B5E901CFb938fa6b6601281cEf679a4)
        //     )
        // );
        // require(success, "Failed to send Ether");
        // vm.stopBroadcast();
    }
}
