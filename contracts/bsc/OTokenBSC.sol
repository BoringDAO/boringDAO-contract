// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../token/BaseToken.sol";

contract OTokenBSC is BaseToken {
    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";
    address public ethToken;

    uint256 public originMintAmout;
    uint256 public crossMintAmount;
    mapping(string => bool) public txMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimal_,
        address admin,
        address _ethToken
    ) public BaseToken(_name, _symbol, decimal_, admin) {
        ethToken = _ethToken;
    }

    function mint(address account, uint256 amount) public override onlyMinter {
        originMintAmout = originMintAmout.add(amount);
        _mint(account, amount);
        OriginMint(account, amount);
    }

    function burn(address account, uint256 amount) public override onlyBurner {
        require(originMintAmout >= amount, "Not enough origin token to burn");
        originMintAmout = originMintAmout.sub(amount);
        _burn(account, amount);
        OriginBurn(account, amount);
    }

    function crossMint(
        address addrFromETH,
        address addrToBSC,
        uint256 amount,
        string memory _txid
    ) public onlyCrosser whenNotMinted(_txid) {
        txMinted[_txid] = true;
        crossMintAmount = crossMintAmount.add(amount);
        _mint(addrToBSC, amount);
        CrossMint(
            ethToken,
            address(this),
            addrFromETH,
            addrToBSC,
            amount,
            _txid
        );
    }

    function crossBurn(address recepient, uint256 amount) public {
        crossMintAmount = crossMintAmount.sub(amount);
        _burn(msg.sender, amount);
        CrossBurn(ethToken, address(this), msg.sender, recepient, amount);
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "caller is not crosser");
        _;
    }

    modifier whenNotMinted(string memory _txid) {
        require(txMinted[_txid] == false, "tx minted");
        _;
    }

    event CrossMint(
        address ethToken,
        address bscToken,
        address from,
        address to,
        uint256 amount,
        string txid
    );
    event CrossBurn(
        address ethToken,
        address bscToken,
        address from,
        address to,
        uint256 amount
    );
    event OriginMint(address account, uint256 amount);
    event OriginBurn(address to, uint256 amount);
}
