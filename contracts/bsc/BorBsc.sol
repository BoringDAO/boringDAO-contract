// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BorBSC is ERC20, Ownable{


    address public crosser;

    event CrossBurn(address from, address recipient, uint amount);
    event CrossMint(address to, uint amount);

    constructor(string memory _name, string memory _symbol, address _crosser) ERC20(_name, _symbol) public {
        crosser = _crosser;
    }

    function setCrosser(address account) public onlyOwner {
        crosser = account;
    }

    function crossMint(address recepient, uint amount) public {
        require(msg.sender == crosser, "BorBSC::mint:only minter can mint");
        _mint(recepient, amount);
        CrossMint(recepient, amount);
    }

    function crossBurn(address recipient, uint amount) public {
        _burn(msg.sender, amount);
        emit CrossBurn(msg.sender, recipient, amount);
    }

}