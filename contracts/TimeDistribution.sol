// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

/**
@notice Linear release of BOR
 */
contract TimeDistribution is Ownable{
    using SafeMath for uint;
    using Math for uint;

    IERC20 public token;

    mapping(address=>uint) public userProportion;
    mapping(address=>uint) public hadGot;

    struct DistributionInfo {
        address user;
        uint amount;
        uint claimedAmount;
        uint startTime;
        uint duration;
    }

    mapping(address=>DistributionInfo) infos;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function userTotalToken() public view returns(uint) {
        DistributionInfo storage info = infos[msg.sender];
        return info.amount;
    }

    function claimed() public view returns(uint) {
        DistributionInfo storage info = infos[msg.sender];
        return info.claimedAmount;
    }

    function addInfo(address account, uint amount, uint startTime, uint duration) public onlyOwner {
        infos[account] = DistributionInfo(account, amount, 0, startTime, duration);
        emit AddInfo(account, amount, startTime, duration);
    }

    function pendingClaim() public view returns(uint) {
        DistributionInfo storage info =  infos[msg.sender];
        uint nowtime = Math.min(block.timestamp, info.startTime+info.duration);
        uint rate = info.duration.div(info.duration);
        return (nowtime - info.startTime).mul(rate).sub(info.claimedAmount);
    }

    function claim() public {
        uint claimAmount =  pendingClaim();
        DistributionInfo storage info =  infos[msg.sender];
        info.claimedAmount = info.claimedAmount.add(claimAmount);
        token.transfer(msg.sender, claimAmount);
        emit ClaimToken(msg.sender, claimAmount);

    }

    event AddInfo(address account, uint amount, uint startTime, uint duration);
    event ClaimToken(address account, uint amount);

    

}