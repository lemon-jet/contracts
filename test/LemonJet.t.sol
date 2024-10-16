// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {LemonJet} from "../src/LemonJet.sol";
import {Vault} from "../src/Vault.sol";
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
    ERC20Mock usdcToken;
    Vault ljtVault;
    Vault usdcVault;
    LemonJet ljtGame;

    MockLinkToken private s_linkToken;

    MockVRFV2PlusWrapper private s_wrapper;

    function setUp() public {
        s_linkToken = new MockLinkToken();
        s_wrapper = new MockVRFV2PlusWrapper(address(s_linkToken), address(1));

        ljtToken = new ERC20Mock();
        usdcToken = new ERC20Mock();

        bytes32 ljtVaultSalt = "LJT_VAULT";
        bytes32 usdcVaultSalt = "USDC_VAULT";
        bytes32 ljtGameSalt = "LJT_GAME";

        bytes memory ljtVaultCreationCode = abi.encodePacked(type(Vault).creationCode);
        bytes memory usdcVaultCreationCode = abi.encodePacked(type(Vault).creationCode);
        bytes memory ljtGameCreationCode = abi.encodePacked(type(LemonJet).creationCode);
        Deployer deployer = new Deployer();

        address ljtVaultAddress = deployer.predictAddr(ljtVaultSalt);
        address usdcVaultAddress = deployer.predictAddr(usdcVaultSalt);
        address ljtGameAddress = deployer.predictAddr(ljtGameSalt);

        ljtVault = Vault(
            deployer.deploy(
                ljtVaultSalt,
                abi.encodePacked(ljtVaultCreationCode, abi.encode(ljtToken, ljtGameAddress, "Vault LJT", "VLJT"))
            )
        );
        usdcVault = Vault(
            deployer.deploy(
                usdcVaultSalt,
                abi.encodePacked(usdcVaultCreationCode, abi.encode(usdcToken, ljtGameAddress, "Vault USDC", "VUSDC"))
            )
        );

        ljtGame = LemonJet(
            deployer.deploy(
                ljtGameSalt,
                abi.encodePacked(
                    ljtGameCreationCode, abi.encode(address(s_wrapper), ljtVaultAddress, usdcVaultAddress, address(0x1))
                )
            )
        );

        ljtToken.mint(playerAddress, 1 ether);
        usdcToken.mint(playerAddress, 1 ether);

        ljtToken.mint(ljtVaultAddress, 500 ether);
        usdcToken.mint(usdcVaultAddress, 500 ether);

        vm.prank(playerAddress);
        ljtToken.approve(ljtGameAddress, type(uint256).max);
        usdcToken.approve(ljtGameAddress, type(uint256).max);

        assertEq(ljtVault.paymentContract(), address(ljtGame));
        assertEq(usdcVault.paymentContract(), address(ljtGame));
        assertEq(ljtGame.ljtVault(), address(ljtVault));
        assertEq(ljtGame.usdcVault(), address(usdcVault));
        assertEq(address(ljtToken), ljtVault.asset());
        assertEq(address(usdcToken), usdcVault.asset());
    }

    function testPlayLjt() public {
        vm.prank(playerAddress);
        vm.deal(playerAddress, 1 ether);
        uint256 requestId = ljtGame.playLjt{value: 1 ether}(1 ether, referralAddress, 150);
        (uint256 wager, address player, uint16 multiplier) = ljtGame.ljtGames(requestId);
        assertEq(wager, 1 ether);
        assertEq(player, playerAddress);
        assertEq(multiplier, 150);

        vm.prank(address(s_wrapper));
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = UINT256_MAX;

        ljtGame.rawFulfillRandomWords(requestId, randomWords);
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
