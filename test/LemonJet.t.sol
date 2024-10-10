// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {LemonJetToken} from "./mocks/LemonJetToken.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract LemonJetTest is Test {
    LemonJet ljtGame;
    LemonJetToken ljtToken;

    function setUp() public {
        // ljtGame = new LemonJet();
        ljtToken = new LemonJetToken("LemonJet Token", "LJT", address(ljtGame));
    }

    function testPlay() public {
        ljtGame.play(1 ether, 10, address(2));
    }
}
