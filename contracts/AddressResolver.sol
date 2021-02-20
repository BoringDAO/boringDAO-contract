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

    mapping(bytes32 =>mapping(bytes32 => address)) public override kk2addr;

    function setAddress(bytes32 key, address addr) public override onlyOwner {
        key2address[key] = addr;
        address2key[addr] = key;
    }

    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external override onlyOwner {
        require(keys.length == addrs.length, "AddressResolver::setMultiAddress:parameter number not match");
        for (uint i=0; i < keys.length; i++) {
            key2address[keys[i]] = addrs[i];
            address2key[addrs[i]] = keys[i];
        }
    }

    function requireAndKey2Address(bytes32 name, string calldata reason) external view override returns(address) {
        address addr = key2address[name];
        require(addr != address(0), reason);
        return addr;
    }

    function setKkAddr(bytes32 k1, bytes32 k2, address addr) public override onlyOwner {
        kk2addr[k1][k2] = addr;
    } 

    function setMultiKKAddr(bytes32[] memory k1s, bytes32[] memory k2s, address[] memory addrs) external override onlyOwner {
        require(k1s.length == k1s.length, "AddressResolver::setMultiKKAddr::parameter key number not match");
        require(k1s.length == addrs.length, "AddressResolver::setMultiKKAddr::parameter key addrs number not match");
        for (uint i=0; i < k1s.length; i++) {
            kk2addr[k1s[i]][k2s[i]] = addrs[i];
        }
    }

    function requireKKAddrs(bytes32 k1, bytes32 k2, string calldata reason) external view override returns(address) {
        address addr = kk2addr[k1][k2];
        require(addr != address(0), reason);
        return addr;
    }

}
