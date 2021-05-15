// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BurnProposal is Ownable{

    using SafeMath for uint;

    struct Proposal {
        string ethHash;
        string btcHash;
        uint256 voteCount;
        bool finished;
        bool isExist;
        mapping(address=>bool) voteState;
    }

    mapping(string => Proposal) public proposals;
    IRole public trustee;
    uint256 public diff=1;
    mapping(string => bool) public proposalResult;

    constructor(address _boringdao) public {
        trustee = IRole(_boringdao);
    }

    function setTrustee(address _trustee) public onlyOwner{
        trustee = IRole(_trustee);
    }

    function setDiff(uint256 _diff) public onlyOwner {
        diff = _diff;
    }

    function approve(string memory ethHash, string memory btcHash, bytes32 _tunnelKey) public onlyTrustee(_tunnelKey) {
        string memory key = string(abi.encodePacked(ethHash, btcHash, _tunnelKey));
        if (proposals[key].isExist == false) {
            Proposal memory p = Proposal({
                ethHash: ethHash,
                btcHash: btcHash,
                voteCount: 1,
                finished: false,
                isExist: true
            });
            proposals[key] = p;
            proposals[key].voteState[msg.sender] = true;
            emit VoteBurnProposal(_tunnelKey, ethHash, btcHash, msg.sender, p.voteCount);
        } else {
            Proposal storage p = proposals[key];
            if(p.voteState[msg.sender] == true) {
                return;
            }
            if(p.finished) {
                return;
            }
            p.voteCount = p.voteCount.add(1);
            p.voteState[msg.sender] = true;
            emit VoteBurnProposal(_tunnelKey, ethHash, btcHash, msg.sender, p.voteCount);
        }
        Proposal storage p = proposals[key];
        uint trusteeCount = getTrusteeCount(_tunnelKey);
        uint threshold = trusteeCount.mod(3) == 0 ? trusteeCount.mul(2).div(3) : trusteeCount.mul(2).div(3).add(diff);
        if (p.voteCount >= threshold) {
            p.finished = true;
            proposalResult[ethHash] = true;
            emit BurnProposalSuccess(_tunnelKey, ethHash, btcHash);
        }
    }

    function getTrusteeCount(bytes32 _tunnelKey) internal view returns(uint){
        return trustee.getRoleMemberCount(_tunnelKey);
    }


    modifier onlyTrustee(bytes32 _tunnelKey) {
        require(trustee.hasRole(_tunnelKey, msg.sender), "Caller is not trustee");
        _;
    }

    event BurnProposalSuccess(
        bytes32 _tunnelKey,
        string ethHash,
        string btcHash
    );

    event VoteBurnProposal(
        bytes32 _tunnelKey,
        string ethHash,
        string btcHash,
        address voter,
        uint256 voteCount
    );
}

interface IRole {
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function hasRole(bytes32 role, address account) external view returns (bool);
}