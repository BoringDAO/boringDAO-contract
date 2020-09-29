// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAddressResolver.sol";

/**
@notice Obtain different contract addresses based on different bytes32(name)
 */
contract AddressResolver is Ownable, IAddressResolver {
    mapping(bytes32 => address) public override key2address;
    mapping(address => bytes32) public override address2key;

    function setAddress(bytes32 key, address addr) public override onlyOwner {
        key2address[key] = addr;
        address2key[addr] = key;
    }

    function requireAndKey2Address(bytes32 name, string calldata reason) external view override returns(address) {
        address addr = key2address[name];
        require(addr != address(0), reason);
        return addr;
    }
}
