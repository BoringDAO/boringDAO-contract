// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CrossLock is AccessControl{

    using SafeERC20 for IERC20;

    mapping(address=>bool) public supportToken;

    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";

    event Lock(address token, address locker, address recipient, uint amount);
    event Unlock(address token, address recipient, uint amount);
    event ChangeAdmin(address oldAdmin, address newAdmin);

    constructor(address _crosser) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CROSSER_ROLE, _crosser);
    }

    function addSupportToken(address[] memory addrs) public onlyAdmin{
        for(uint i; i<addrs.length;i++) {
            require(supportToken[addrs[i]] == false, "Toke already Supported");
            supportToken[addrs[i]] = true;
        }
    }

    function removeSupportToken(address[] memory addrs) public onlyAdmin {
        for(uint i; i<addrs.length;i++) {
            require(supportToken[addrs[i]] == true, "Toke not Supported");
            supportToken[addrs[i]] = false;
        }
    }

    function lock(address token, address recipient, uint amount) public onlySupportToken(token) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Lock(token, msg.sender, recipient, amount);
    }

    function unlock(address token, address recipient, uint amount) public onlySupportToken(token) onlyCrosser {
        IERC20(token).safeTransfer(recipient, amount);
        emit Unlock(token, recipient, amount);
    }

    modifier onlySupportToken(address token) {
        require(supportToken[token] == true, "Lock::Not Support Token");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not admin");
        _;
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "caller is not crosser");
        _;
    }
    
}