// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAddressBook.sol";

/**
@notice AddressBook records the multi-signature wallet address of the underlying asset and 
the correspondence between the user's Ethereum address and other asset addresses
 */
contract AddressBook is Ownable, IAddressBook {
    // BTC => BTC address => eth address
    mapping(bytes32 => mapping(string => address)) public override asset2eth;
    // eth address => BTC => BTC address
    mapping(address => mapping(bytes32 => string)) public override eth2asset;
    // multiSign asset address
    mapping(string => string) public override assetMultiSignAddress;

    /**
    @param assetName eg.bytes32("BTC")
    @param assetAddr eg. user bitcoin address
     */
    function setAddress(bytes32 assetName, string memory assetAddr)
        public
        override
    {
        asset2eth[assetName][assetAddr] = msg.sender;
        eth2asset[msg.sender][assetName] = assetAddr;
    }
    
    function setAssetMultiSignAddress(string memory symbol, string memory addr) external override onlyOwner{
        assetMultiSignAddress[symbol] = addr;
    }
}
