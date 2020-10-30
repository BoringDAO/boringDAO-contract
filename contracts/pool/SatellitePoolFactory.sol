// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StakingRewardsLockFactory.sol";
import "../interface/ISatellitePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SatellitePool.sol";

contract SatellitePoolFactory is Ownable{

    using SafeMath for uint256;

    address public rewardsToken;
    uint256 public stakingRewardsGenesis;

    address[] public stakingTokens;
    mapping(address => address) poolByStakingToken;


    constructor(address _rewardsToken, uint256 _stakingRewardsGenesis)
        public
        Ownable()
    {
        require(
            _stakingRewardsGenesis >= block.timestamp,
            "StakingRewardsFactory::constructor: genesis too soon"
        );

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }


     function satelliteTVL() public view returns (uint256) {
        uint256 tvl = 0;
        for (uint256 i = 0; i < stakingTokens.length; i++) {
            address token = stakingTokens[i];
            address rewardsAddress = poolByStakingToken[token];
            tvl = tvl.add(ISatellitePool(rewardsAddress).tvl());
        }
        return tvl;
    }

    function deploy(address stakingToken, address _liquidator, address _oracle, bytes32 _sts) public onlyOwner {

        require(
            poolByStakingToken[stakingToken] == address(0),
            "StakingRewardsFactory::deploy: already deployed"
        );

        poolByStakingToken[stakingToken] = address(
            new SatellitePool(
                _liquidator,
                address(this),
                rewardsToken,
                stakingToken,
                _oracle,
                _sts
            )
        );
        stakingTokens.push(stakingToken);
    }

    function notifyRewardAmount(
        address stakingToken,
        uint256 duration,
        uint256 rewardAmount
    ) public onlyOwner {
        require(
            block.timestamp >= stakingRewardsGenesis,
            "StakingRewardsFactory::notifyRewardAmount: not ready"
        );
        require(
            poolByStakingToken[stakingToken] != address(0),
            "StakingRewardsFactory::notifyRewardAmount: not deployed"
        );

        require(
            IERC20(rewardsToken).transfer(poolByStakingToken[stakingToken], rewardAmount),
            "StakingRewardsFactory::notifyRewardAmount: transfer failed"
        );
        StakingRewardsLock(poolByStakingToken[stakingToken]).notifyRewardAmount(
            rewardAmount,
            duration
        );
    }
}