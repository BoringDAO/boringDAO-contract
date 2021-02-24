// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../token/BaseToken.sol";

contract OTokenBSC is BaseToken {
    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";
    address public ethToken;
    
    uint public originMintAmout;
    uint public crossMintAmount;
    constructor(string memory _name, string memory _symbol, uint8 decimal_, address admin, address _ethToken) public BaseToken(_name, _symbol, decimal_, admin) {
        ethToken = _ethToken;
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

    function crossMint(address addrFromETH, address addrToBSC, uint amount) public onlyCrosser{
        crossMintAmount = crossMintAmount.add(amount);
        _mint(addrToBSC, amount);
        CrossMint(ethToken, address(this), addrFromETH, addrToBSC, amount);
    }

    function crossBurn(address recepient, uint amount) public {
        crossMintAmount = crossMintAmount.sub(amount);
        _burn(msg.sender, amount);
        CrossBurn(ethToken, address(this), msg.sender, recepient, amount);
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "caller is not crosser");
        _;
    }

    event CrossMint(address ethToken, address bscToken, address from, address to, uint amount);
    event CrossBurn(address ethToken, address bscToken, address from, address to, uint amount);
    event OriginMint(address account, uint amount);
    event OriginBurn(address to, uint amount);


}