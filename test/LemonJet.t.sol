// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {Vault} from "../src/Vault.sol";
import {VRFV2PlusClient} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Create2} from "../src/utils/Create2.sol";

import {MockLinkToken} from "@chainlink-contracts-1.2.0/src/v0.8/mocks/MockLinkToken.sol";

import {ExposedVRFCoordinatorV2_5} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev//testhelpers/ExposedVRFCoordinatorV2_5.sol";
import {MockV3Aggregator} from "@chainlink-contracts-1.2.0/src/v0.8/tests/MockV3Aggregator.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract LemonJetTest is Test {
    address constant treasury = address(0x1);
    ERC20Mock ljtToken;
    ERC20Mock usdcToken;
    Vault ljtVault;
    Vault usdcVault;
    LemonJet ljtGame;

    ExposedVRFCoordinatorV2_5 private s_testCoordinator;
    MockLinkToken private s_linkToken;
    MockV3Aggregator private s_linkNativeFeed;
    VRFV2PlusWrapper private s_wrapper;
    VRFV2PlusWrapperConsumerExample private s_consumer;

    function setUp() public {
        // Deploy link token and link/native feed.
        s_linkToken = new MockLinkToken();
        s_linkNativeFeed = new MockV3Aggregator(18, 500000000000000000); // .5 ETH (good for testing)

        // Deploy coordinator.
        s_testCoordinator = new ExposedVRFCoordinatorV2_5(address(0));

        // Create subscription for all future wrapper contracts.
        s_wrapperSubscriptionId = s_testCoordinator.createSubscription();

        // Deploy wrapper.
        s_wrapper = new VRFV2PlusWrapper(
            address(s_linkToken),
            address(s_linkNativeFeed),
            address(s_testCoordinator),
            uint256(s_wrapperSubscriptionId)
        );

        ljtToken = new ERC20Mock();
        usdcToken = new ERC20Mock();

        vm.deal(address(0x1), 100 ether);
        vm.startPrank(address(0x1));
        bytes32 ljtVaultSalt = "LJT_VAULT";
        bytes32 usdcVaultSalt = "USDC_VAULT";
        bytes32 ljtGameSalt = "LJT_GAME";

        bytes memory ljtVaultCreationCode = abi.encodePacked(
            type(Vault).creationCode
        );
        bytes memory usdcVaultCreationCode = abi.encodePacked(
            type(Vault).creationCode
        );
        bytes memory ljtGameCreationCode = abi.encodePacked(
            type(LemonJet).creationCode
        );
        Create2 create2 = new Create2();

        address ljtVaultAddress = create2.computeAddress(
            ljtVaultSalt,
            keccak256(ljtVaultCreationCode)
        );
        address usdcVaultAddress = create2.computeAddress(
            usdcVaultSalt,
            keccak256(usdcVaultCreationCode)
        );
        address ljtGameAddress = create2.computeAddress(
            ljtGameSalt,
            keccak256(ljtGameCreationCode)
        );

        ljtVault = new Vault(ljtToken, ljtGameAddress, "Vault LJT", "VLJT");
        usdcVault = new Vault(ljtToken, ljtGameAddress, "Vault USDC", "VUSDC");
        ljtGame = new LemonJet(
            address(ljtToken),
            address(ljtVault),
            address(usdcVault),
            address(0x1)
        );

        assertEq(ljtVault.paymentContract(), address(ljtGame));
        assertEq(usdcVault.paymentContract(), address(ljtGame));
        assertEq(ljtGame.ljtVault(), address(ljtVault));
        assertEq(ljtGame.usdcVault(), address(usdcVault));
        assertEq(address(ljtToken), ljtVault.asset());
        assertEq(address(usdcToken), usdcVault.asset());
    }

    function testDeploy() public {}
}
