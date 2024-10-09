// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LemonJetToken is ERC20 {
    address public lj;

    constructor(
        string memory name_,
        string memory symbol_,
        address _lj
    ) ERC20(name_, symbol_) {
        lj = _lj;
        _mint(address(this), 1000_000_000 * 1 ether);
        _transfer(address(this), lj, 400_000_000 * 1 ether);
    }

    // todo remove
    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

    function transferWager(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == lj, "Sender is not LemonJet");
        _transfer(from, to, amount);
        return true;
    }

    function transferReward(
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == lj, "Sender is not LemonJet");
        _transfer(lj, to, amount);
        return true;
    }
}
