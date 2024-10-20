// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {Referral} from "../src/Referral.sol";
import {HelperContract} from "./HelperContract.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Deployer} from "../src/utils/create3/Deployer.sol";

import {MockLinkToken} from "@chainlink-contracts-1.2.0/src/v0.8/mocks/MockLinkToken.sol";

// import {ExposedVRFCoordinatorV2_5} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev//testhelpers/ExposedVRFCoordinatorV2_5.sol";
// import {MockV3Aggregator} from "@chainlink-contracts-1.2.0/src/v0.8/tests/MockV3Aggregator.sol";
import {MockVRFV2PlusWrapper} from "./mocks/MockVRFV2PlusWrapperMock.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract LemonJetTest is Test, HelperContract {
    address constant referralAddress = address(5);
    ERC20Mock ljtToken;
    Referral referrals;
    ERC20Mock usdcToken;
    LemonJet ljtGame;

    MockLinkToken private s_linkToken;

    MockVRFV2PlusWrapper private s_wrapper;

    function setUp() public {
        s_linkToken = new MockLinkToken();
        s_wrapper = new MockVRFV2PlusWrapper(address(s_linkToken), address(1));
        ljtToken = new ERC20Mock();
        referrals = new Referral();
        ljtGame = new LemonJet(
            address(s_wrapper), reserveFund, address(ljtToken), address(referrals), "Vault LemonJet", "VLJT"
        );
        ljtToken.mint(address(ljtGame), 500 ether);
        ljtToken.mint(player, 500 ether);
        vm.prank(player);
        ljtToken.approve(address(ljtGame), UINT256_MAX);
    }

    function testPlayLjt() public {
        vm.prank(player);
        vm.deal(player, 1 ether);
        ljtGame.play{value: 1 ether}(1 ether, 150, referralAddress);
        uint256 requestId = s_wrapper.lastRequestId();

        address _player = ljtGame.requestIdToPlayer(requestId);

        (uint256 potentialWinnings, uint256 threshold, uint8 statusBeforeRelease) = ljtGame.games(player);
        assertEq(potentialWinnings, (1 ether * 150) / 100);
        assertEq(statusBeforeRelease, 1);
        assertEq(_player, player);

        vm.prank(address(s_wrapper));
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = UINT256_MAX;

        ljtGame.rawFulfillRandomWords(requestId, randomWords);

        (,, uint8 statusAfterRelease) = ljtGame.games(player);

        assertEq(statusAfterRelease, 2);
    }

    function testFailPlayBeforeRelease() public {
        vm.prank(player);
        vm.deal(player, 1 ether);
        ljtGame.play{value: 1 ether}(1 ether, 150, referralAddress);
        ljtGame.play{value: 1 ether}(1 ether, 150, referralAddress);
    }
}
