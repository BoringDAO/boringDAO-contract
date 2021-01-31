// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interface/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IStableSwapOBTC.sol";

contract Barter is Ownable, Pausable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    uint public doubleNumber = 2e18;
    IStableSwapOBTC public sso;
    IOracle public oracle;
    IERC20 public bor;
    IERC20 public oBTC;
    IERC20 public renBTC;
    IERC20 public wBTC;
    address public distributor;

    uint public maxMintAmount=2000e18;
    uint public mintedAmount;

    constructor(address _sso, address _oracle, address _bor, address _distributor, address _obtc, address _renBTC, address _wBTC) public {
        sso = IStableSwapOBTC(_sso);
        oracle = IOracle(_oracle);
        bor = IERC20(_bor);
        distributor = _distributor;
        oBTC = IERC20(_obtc);
        renBTC = IERC20(_renBTC);
        wBTC = IERC20(_wBTC);
    }


    function setDoubleNumber(uint number) public onlyOwner{
        doubleNumber = number;
    }

    function setOracle(address _oracle) public onlyOwner{
        oracle = IOracle(_oracle);
    }

    function setDistributor(address _distributor) public onlyOwner{
        distributor = _distributor;
    }

    function setMaxMintAmount(uint amount) public onlyOwner{
        maxMintAmount = amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // 0 -> obtc, 1 -> renBTC, 2 -> wBTC
    function trade(int128 token, uint amount, uint min_dy) public whenNotPaused nonReentrant {
        if(token == 1) {
            renBTC.safeTransferFrom(msg.sender, address(this), amount);
            renBTC.approve(address(sso), amount);
        } else if(token == 2) {
            wBTC.safeTransferFrom(msg.sender, address(this), amount);
            wBTC.approve(address(sso), amount);
        } else {
            revert("not support token");
        }

        uint dy = sso.exchange_underlying(token, 0, amount, min_dy);
        uint feeBor = calculateFeeBor(dy);
        if (feeBor != 0) {
            mintedAmount = mintedAmount.add(feeBor);
            bor.safeTransferFrom(distributor, msg.sender, feeBor);
        }
        oBTC.safeTransfer(msg.sender, dy);
    }

    // 0 -> obtc, 1 -> renBTC, 2 -> wBTC
    function estimate(int128 token, uint amount) public view returns (uint, uint){
        uint dy = sso.get_dy_underlying(token, 0, amount);
        uint feeBor = calculateFeeBor(dy);
        return (dy, feeBor);
    }

    function calculateFeeBor(uint dy) internal view returns (uint) {
        uint feeRatio = sso.fee().mul(1e8);
        uint feeBTC = dy.divideDecimal(10**18-feeRatio).multiplyDecimal(feeRatio);
        uint feeBor = feeBTC.multiplyDecimal(oracle.getPrice(bytes32("BTC"))).divideDecimal(oracle.getPrice(bytes32("BOR"))).multiplyDecimal(doubleNumber);
        if (feeBor.add(mintedAmount) >= maxMintAmount) {
            feeBor = maxMintAmount.sub(mintedAmount);
        }
        return feeBor;
    }
}