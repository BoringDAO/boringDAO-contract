// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Tunnel.sol";
import "./token/PPToken.sol";
import "./token/BTokenSnapshot.sol";
import "./token/PPToken.sol";

contract TunnelCreator {
    IAddressResolver public addrReso;

    constructor(IAddressResolver _addrReso) public {
        addrReso = _addrReso;
    }

    function create(bytes32 _tunnelKey, bytes32 _bTokenKey, string memory ) public {
        require(addrReso.key2address(_tunnelKey) == address(0), "exist tunnelKey");
        require(addrReso.key2address(_bTokenKey) == address(0), "exist bTokenKey");
        Tunnel tunnel = new Tunnel(addrReso, _tunnelKey, _bTokenKey);
    }
}