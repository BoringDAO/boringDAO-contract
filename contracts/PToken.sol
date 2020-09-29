// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAddressResolver.sol";

/**
@notice When the user pledge the BOR to the tunnel, he will get PToken
 */
contract PToken is Ownable, ERC20 {
    bytes32 public tunnelContractKey;
    IAddressResolver addrReso;

    constructor(
        string memory _name,
        string memory _symbol,
        IAddressResolver _addrReso,
        bytes32 _tunnelContractKey
    ) public ERC20(_name, _symbol) {
        addrReso = _addrReso;
        tunnelContractKey = _tunnelContractKey;
    }

    function tunnelContract() internal view returns (address) {
        return addrReso.key2address(tunnelContractKey);
    }

    function mintByTunnel(address to, uint256 amount) external onlyTunnel {
        _mint(to, amount);
    }

    function burnByTunnel(address account, uint256 amount) external onlyTunnel {
        _burn(account, amount);
    }

    function transferByTunnel(
        address from,
        address to,
        uint256 amount
    ) external onlyTunnel {
        _transfer(from, to, amount);
    }

    modifier onlyTunnel {
        require(
            msg.sender == tunnelContract(),
            "caller is not tunnel contract in PToken"
        );
        _;
    }
}
