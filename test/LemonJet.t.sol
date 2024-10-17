// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {ReferralsLemonJet} from "../src/ReferralsLemonJet.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Deployer} from "../src/utils/create3/Deployer.sol";

import {MockLinkToken} from "@chainlink-contracts-1.2.0/src/v0.8/mocks/MockLinkToken.sol";

// import {ExposedVRFCoordinatorV2_5} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev//testhelpers/ExposedVRFCoordinatorV2_5.sol";
// import {MockV3Aggregator} from "@chainlink-contracts-1.2.0/src/v0.8/tests/MockV3Aggregator.sol";
import {MockVRFV2PlusWrapper} from "./mocks/MockVRFV2PlusWrapperMock.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract LemonJetTest is Test {
    address constant treasury = address(3);
    address constant playerAddress = address(4);
    address constant referralAddress = address(5);
    ERC20Mock ljtToken;
    ReferralsLemonJet referrals;
    ERC20Mock usdcToken;
    LemonJet ljtGame;

    MockLinkToken private s_linkToken;

    MockVRFV2PlusWrapper private s_wrapper;

    function setUp() public {
        s_linkToken = new MockLinkToken();
        s_wrapper = new MockVRFV2PlusWrapper(address(s_linkToken), address(1));
        ljtToken = new ERC20Mock();
        referrals = new ReferralsLemonJet();
        ljtGame =
            new LemonJet(address(s_wrapper), treasury, address(ljtToken), address(referrals), "Vault LemonJet", "VLJT");
        ljtToken.mint(address(ljtGame), 500 ether);
        ljtToken.mint(playerAddress, 500 ether);
        vm.prank(playerAddress);
        ljtToken.approve(address(ljtGame), UINT256_MAX);
    }

    function testPlayLjt() public {
        vm.prank(playerAddress);
        vm.deal(playerAddress, 1 ether);
        ljtGame.play{value: 1 ether}(1 ether, referralAddress, 150);
        uint256 requestId = s_wrapper.lastRequestId();

        address player = ljtGame.requestIdToPlayer(requestId);

        (uint256 wager, uint16 multiplier, uint8 isRunning) = ljtGame.games(player);
        assertEq(wager, 1 ether);
        assertEq(isRunning, 2);
        assertEq(player, playerAddress);
        assertEq(multiplier, 150);

        vm.prank(address(s_wrapper));
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = UINT256_MAX;

        ljtGame.rawFulfillRandomWords(requestId, randomWords);

        (,, isRunning) = ljtGame.games(player);

        assertEq(isRunning, 1);
    }

    // function testReleaseLjt() public {
    //     vm.prank(address(s_wrapper));
    //     uint256 requestId = 0x42;
    //     uint256[] memory randomWords = new uint256[](1);
    //     bytes32 storageSlot = keccak256(abi.encode(requestId, requestId));
    //     vm.store(
    //         address(ljtGame),
    //         storageSlot,
    //         bytes(abi.encode(1 ether, playerAddress, uint16(150)))
    //     );
    //     randomWords[0] = UINT256_MAX;
    //
    //     ljtGame.rawFulfillRandomWords(requestId, randomWords);
    // }
}
