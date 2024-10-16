// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Create3} from "./Create3.sol";

contract Deployer {
    function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
        */

        return abi.encodePacked(hex"63", uint32(_code.length), hex"80600E6000396000F3", _code);
    }

    function predictAddr(bytes32 salt) public view returns (address addr) {
        return Create3.addressOf(salt);
    }

    function deploy(bytes32 salt, bytes memory runtimeCode) public payable returns (address addr) {
        return Create3.create3(salt, runtimeCode, msg.value);
    }
}
