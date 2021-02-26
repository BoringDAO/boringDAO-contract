// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../interface/ISatellitePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./SatellitePool.sol";

contract SatellitePoolFactoryV2 is Ownable{

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    EnumerableSet.AddressSet private poolSet;


    function satelliteTVL() public view returns (uint256) {
        uint256 tvl = 0;
        for (uint256 i; i < poolSet.length(); i++) {
            address pool = poolSet.at(i);
            tvl = tvl.add(ISatellitePool(pool).tvl());
        }
        return tvl;
    }

    function addPools(address[] calldata addrs) public onlyOwner{
        for(uint i; i < addrs.length; i++) {
            poolSet.add(addrs[i]);
        }
    }

    function removePools(address[] calldata addrs) public onlyOwner{
        for(uint i; i < addrs.length; i++) {
            poolSet.remove(addrs[i]);
        }
    }

}