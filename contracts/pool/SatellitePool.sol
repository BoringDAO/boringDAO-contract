// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StakingRewardsLock.sol";
import "../interface/IOracle.sol";
import "../lib/SafeDecimalMath.sol";
import "../interface/ILiquidate.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interface/IPause.sol";

contract SatellitePool is StakingRewardsLock, ILiquidate, Pausable, IPause{
    using SafeDecimalMath for uint;

    address public liquidation;
    IOracle public oracle;
    bytes32 public stakingTokenSymbol;

    constructor(
        address _liquidation,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _oracle,
        bytes32 _sts,
        uint256 _lockDuration,
        uint256 _unlockPercent,
        uint256 _lockPercent
    ) public 
        StakingRewardsLock(_rewardsDistribution, _rewardsToken, _stakingToken, _lockDuration, _unlockPercent, _lockPercent)
    {
        liquidation = _liquidation;
        oracle = IOracle(_oracle);
        stakingTokenSymbol = _sts;
    }

    function liquidate(address account) public override onlyLiquidation {
        stakingToken.safeTransfer(account, stakingToken.balanceOf(address(this)));
    }

    function tvl() public view returns(uint){
        uint tokenAmount = stakingToken.balanceOf(address(this));
        uint price = oracle.getPrice(stakingTokenSymbol);
        return tokenAmount.multiplyDecimal(price);
    }
    
    function withdraw(uint amount) public override whenNotPaused{
        super.withdraw(amount);
    } 

    function pause() public override onlyLiquidation {
        _pause();
    }

    function unpause() public override onlyLiquidation {
        _unpause();
    }

    modifier onlyLiquidation {
        require(msg.sender == liquidation, "caller is not liquidator");
        _;
    }
}
