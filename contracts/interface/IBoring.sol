// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IBoring {
    function openTrack(bytes32 trackName) external; 
    function pledge(bytes32 trackName, uint amount) external;
    function redeem(bytes32 _trackKey, uint _amount) external;
    function burnBToken(bytes32 _trackKey, uint _amount, string calldata assetAddress) external;
    function approveMint(bytes32 _trackKey, bytes32 _txid, uint _amount, address _account) external;

    function getProposers() external returns(address[] memory);
}
