// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {LemonJetEntropy} from "../src/LemonJetEntropy.sol";
import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import {Asset} from "../test/Asset.sol";
import {LemonJetToken} from "../test/mocks/LemonJetToken.sol";

contract PlayLemonJetEntropyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address entropyProviderAddress = vm.envAddress("ENTROPY_PROVIDER");
        LemonJetEntropy ljtGame = LemonJetEntropy(payable(address(0x2a95Ac58764281AD1A07Da9e14857D615581C7e9)));
        IEntropy entropyProvider = IEntropy(entropyProviderAddress);

        vm.startBroadcast(deployerPrivateKey);
        uint256 fee = entropyProvider.getFee(entropyProviderAddress);
        // ljtGame.play{value: fee}(
        //     500000000000000000000,
        //     200,
        //     0xBa0d95449B5E901CFb938fa6b6601281cEf679a4,
        //     bytes32(uint256(42))
        // );
        console2.log(fee);
        vm.stopBroadcast();
    }
}
