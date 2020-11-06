// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StakingRewardsLock.sol";
import "../interface/IOracle.sol";
import "../lib/SafeDecimalMath.sol";
import "../interface/ILiquidate.sol";

contract SatellitePool is StakingRewardsLock, ILiquidate {
    using SafeDecimalMath for uint;

    address public liquidator;
    IOracle public oracle;
    bytes32 public stakingTokenSymbol;

    constructor(
        address _liquidator,
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
        liquidator = _liquidator;
        oracle = IOracle(_oracle);
        stakingTokenSymbol = _sts;
    }

    function liquidate() public override onlyLiquidator {
        stakingToken.safeTransfer(liquidator, stakingToken.balanceOf(address(this)));
    }

    function tvl() public view returns(uint){
        uint tokenAmount = stakingToken.balanceOf(address(this));
        uint price = oracle.getPrice(stakingTokenSymbol);
        return tokenAmount.multiplyDecimal(price);
    }

    modifier onlyLiquidator {
        require(msg.sender == liquidator, "caller is not liquidator");
        _;
    }
}
