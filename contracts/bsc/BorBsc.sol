// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BorBSC is ERC20, AccessControl {
    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";

    address public ethBor;

    event CrossBurn(
        address ethToken,
        address bscToken,
        address from,
        address to,
        uint256 amount
    );
    event CrossMint(
        address ethTokenr,
        address bscToken,
        address from,
        address to,
        uint256 amount
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
        uint256 amount
    ) public onlyCrosser{
        _mint(recepient, amount);
        CrossMint(ethBor, address(this), addrFromETH, recepient, amount);
    }

    function crossBurn(address recipient, uint256 amount) public {
        _burn(msg.sender, amount);
        emit CrossBurn(ethBor, address(this), msg.sender, recipient, amount);
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "BorBSC::caller is not crosser");
        _;
    }
}
