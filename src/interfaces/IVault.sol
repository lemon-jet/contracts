// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface IVault is IERC4626 {
    event PayoutWin(address indexed receiver, uint256 assets);

    function maxWinAmount() external view returns (uint256);
}
