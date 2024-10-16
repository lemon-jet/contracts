// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LemonJetToken is Ownable, ERC20 {
    address public lj;

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {
        // _mint(address(this), 1000_000_000 * 1 ether);
        // _transfer(address(this), lj, 400_000_000 * 1 ether);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function transferWager(address from, address to, uint256 amount) external returns (bool) {
        require(msg.sender == lj, "Sender is not LemonJet");
        _transfer(from, to, amount);
        return true;
    }

    function transferReward(address to, uint256 amount) external returns (bool) {
        require(msg.sender == lj, "Sender is not LemonJet");
        _transfer(lj, to, amount);
        return true;
    }

    function setLj(address _lj) external onlyOwner {
        lj = _lj;
    }
}
