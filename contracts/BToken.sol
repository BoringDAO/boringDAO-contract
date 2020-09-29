// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IAddressResolver.sol";
import "./interface/IBToken.sol";

/**
@notice eg bBTC
 */
contract BToken is ERC20, IBToken {
    bytes32 public tunnelKey;
    IAddressResolver addrResolver;

    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _tunnelKey,
        IAddressResolver _addrResolver
    ) public ERC20(_name, _symbol) {
        tunnelKey = _tunnelKey;
        addrResolver = _addrResolver;
    }

    modifier onlyTunnel {
        require(msg.sender == addrResolver.key2address(tunnelKey));
        _;
    }

    function mintByTunnel(address account, uint256 amount)
        external
        override
        onlyTunnel
    {
        _mint(account, amount);
    }

    function burnByTunnel(address account, uint256 amount)
        external
        override
        onlyTunnel
    {
        _burn(account, amount);
    }

    function transferByTunnel(
        address from,
        address to,
        uint256 amount
    ) external override onlyTunnel {
        _transfer(from, to, amount);
    }
}
