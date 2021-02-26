// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BorBSC is ERC20, AccessControl {
    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";

    address public ethBor;
    mapping(string => bool) public txMinted;

    event CrossBurn(
        address ethToken,
        address bscToken,
        address from,
        address to,
        uint256 amount
    );
    event CrossMint(
        address ethToken,
        address bscToken,
        address from,
        address to,
        uint256 amount,
        string txid
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _crosser,
        address _ethBor
    ) public ERC20(_name, _symbol) {
        ethBor = _ethBor;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CROSSER_ROLE, _crosser);
    }

    function crossMint(
        address addrFromETH,
        address recepient,
        uint256 amount,
        string memory _txid
    ) public onlyCrosser whenNotMinted(_txid) {
        txMinted[_txid] = true;
        _mint(recepient, amount);
        CrossMint(ethBor, address(this), addrFromETH, recepient, amount, _txid);
    }

    function crossBurn(address recipient, uint256 amount) public {
        _burn(msg.sender, amount);
        emit CrossBurn(ethBor, address(this), msg.sender, recipient, amount);
    }

    modifier onlyCrosser {
        require(
            hasRole(CROSSER_ROLE, msg.sender),
            "BorBSC::caller is not crosser"
        );
        _;
    }

    modifier whenNotMinted(string memory _txid) {
        require(txMinted[_txid] == false, "tx minted");
        _;
    }
}
