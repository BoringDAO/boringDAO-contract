// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../token/BaseToken.sol";

contract OTokenBSC is BaseToken {
    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";
    
    uint public originMintAmout;
    uint public crossMintAmount;
    constructor(string memory _name, string memory _symbol, uint8 decimal_, address admin) public BaseToken(_name, _symbol, decimal_, admin) {

    }

    function mint(address account, uint amount) public  override onlyMinter{
        originMintAmout = originMintAmout.add(amount);
        _mint(account, amount);
        OriginMint(account, amount);
    }

    function burn(address account, uint amount) public  override onlyBurner{
        originMintAmout = originMintAmout.sub(amount);
        _burn(account, amount);
        OriginBurn(account, amount);
    }

    function crossMint(address account, uint amount) public onlyCrosser{
        crossMintAmount = crossMintAmount.add(amount);
        _mint(account, amount);
        CrossMint(account, amount);
    }

    function crossBurn(address recepient, uint amount) public {
        crossMintAmount = crossMintAmount.sub(amount);
        _burn(msg.sender, amount);
        CrossBurn(msg.sender, recepient, amount);
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "caller is not crosser");
        _;
    }

    event CrossMint(address account, uint amount);
    event CrossBurn(address from, address to, uint amount);
    event OriginMint(address account, uint amount);
    event OriginBurn(address to, uint amount);


}