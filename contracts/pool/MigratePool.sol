// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IMintBurn.sol";
import "../lib/SafeDecimalMath.sol";

contract MigratePool is Ownable{

    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public balanceOf;
    IERC20 public depositToken;
    address public withdrawToken;
    uint public feeRate;
    uint public decimalDiff;
    
    constructor(address _depositToken, address _withdrawToken, uint _feeRate, uint _decimalDiff) public {
        depositToken = IERC20(_depositToken);
        withdrawToken = _withdrawToken;
        feeRate = _feeRate;
        decimalDiff = 10 ** _decimalDiff;
    }

    function deposit(uint amount) public {
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount); 
        uint issueAmount = amount.mul(decimalDiff).multiplyDecimal(feeRate);
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        IMintBurn(withdrawToken).mint(msg.sender, issueAmount);
        emit MigrateToken(msg.sender, amount, issueAmount, feeRate);
    }

    function modifyFeeRate(uint _feeRate) public onlyOwner {
        feeRate = _feeRate;
    }

    event MigrateToken(address user, uint amount, uint issueAmount, uint feeRate);

}