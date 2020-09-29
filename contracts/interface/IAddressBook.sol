// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IAddressBook {
    function asset2eth(bytes32 assetName, string memory assetAddr) external view returns(address); 
    function eth2asset(address ethAddress, bytes32 assetName) external view returns(string memory); 
    function assetMultiSignAddress(string memory asset) external view returns(string memory);
    function setAddress(bytes32 assetName, string memory assetAddr) external;
    function setAssetMultiSignAddress(string memory symbol, string memory addr) external;
}