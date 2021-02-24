// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/SafeDecimalMath.sol";


contract CrossLock is AccessControl{

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";

    // ethToken => bscToken
    mapping(address=>address) public supportToken;
    mapping(address=>mapping(address=>uint)) public lockAmount;

    // fee
    // leave ethereum
    mapping(address=>uint) public lockFeeRatio;
    mapping(address=>uint) public lockFeeAmount;
    // back ethereum
    mapping(address=>uint) public unlockFeeRatio;
    mapping(address=>uint) public unlockFeeAmount;
    //
    address public feeTo;


    event Lock(address ethToken, address bscToken, address locker, address recipient, uint amount);
    event Unlock(address ethToken, address bscToken, address from, address recipient, uint amount);
    event ChangeAdmin(address oldAdmin, address newAdmin);

    constructor(address _crosser, address _feeTo) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CROSSER_ROLE, _crosser);
        feeTo = _feeTo;

    }

    function addSupportToken(address ethTokenAddr, address bscTokenAddr) public onlyAdmin {
        require(supportToken[ethTokenAddr] == address(0), "Toke already Supported");
        supportToken[ethTokenAddr] = bscTokenAddr;
    }

    function removeSupportToken(address ethTokenAddr) public onlyAdmin {
        require(supportToken[ethTokenAddr] != address(0), "Toke not Supported");
        delete supportToken[ethTokenAddr];
    }

    function addSupportTokens(address[] memory ethTokenAddrs, address[] memory bscTokenAddrs) public {
        require(ethTokenAddrs.length==bscTokenAddrs.length, "Token length not match");
        for(uint i; i<ethTokenAddrs.length;i++) {
            addSupportToken(ethTokenAddrs[i], bscTokenAddrs[i]);
        }
    }

    function removeSupportTokens(address[] memory addrs) public {
        for(uint i; i<addrs.length;i++) {
            removeSupportToken(addrs[i]);
        }
    }

    function setFee(address token, uint _lockFeeAmount, uint _lockFeeRatio, uint _unlockFeeAmount, uint _unlockFeeRatio) public onlyAdmin {
        require(supportToken[token] != address(0), "Toke not Supported");
        lockFeeAmount[token] = _lockFeeAmount;
        lockFeeRatio[token] = _lockFeeRatio;
        unlockFeeAmount[token] = _unlockFeeAmount;
        unlockFeeRatio[token] = _unlockFeeRatio;
    }

    function calculateFee(address token, uint amount, uint crossType) public view returns(uint feeAmount, uint remainAmount) {
        uint _feeMinAmount;
        uint _feeRatio;
        if (crossType == 0) {
            // leave ethereum
            _feeMinAmount = lockFeeAmount[token];
            _feeRatio = lockFeeRatio[token];
        } else {
            // back ethereum
            _feeMinAmount = unlockFeeAmount[token];
            _feeRatio = unlockFeeRatio[token];
        }
        feeAmount = _feeMinAmount.add(amount.multiplyDecimal(_feeRatio));
        remainAmount = amount.sub(feeAmount);
    }

    function lock(address token, address recipient, uint amount) public onlySupportToken(token) {
        (uint feeAmount, uint remainAmount) = calculateFee(token, amount, 0);
        lockAmount[token][msg.sender] = lockAmount[token][msg.sender].add(remainAmount);
        IERC20(token).safeTransferFrom(msg.sender, feeTo, feeAmount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), remainAmount);
        emit Lock(token, supportToken[token], msg.sender, recipient, remainAmount);
    }

    function unlock(address token, address from, address recipient, uint amount) public onlySupportToken(token) onlyCrosser {
        (uint feeAmount, uint remainAmount) = calculateFee(token, amount, 1);
        lockAmount[token][recipient] = lockAmount[token][recipient].sub(amount);
        IERC20(token).safeTransfer(feeTo, feeAmount);
        IERC20(token).safeTransfer(recipient, remainAmount);
        emit Unlock(token, supportToken[token], from, recipient, amount);
    }

    modifier onlySupportToken(address token) {
        require(supportToken[token] != address(0), "Lock::Not Support Token");
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