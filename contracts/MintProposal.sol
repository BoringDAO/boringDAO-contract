// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interface/IAddressResolver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IMintProposal.sol";

contract MintProposal is IMintProposal {
    using SafeMath for uint256;

    bytes32 public constant BORINGDAO = "BoringDAO";
    IAddressResolver addrReso;

    constructor(IAddressResolver _addrResovler) public {
        addrReso = _addrResovler;
    }

    struct Proposal {
        bytes32 tunnelKey;
        string assetAddress;
        string txid;
        uint256 amount;
        address creater;
        uint256 voteCount;
        bool finished;
        bool isExist;
        mapping(address => bool) voteState;
    }
    // mapping(address => bool) voteState;

    mapping(bytes32 => Proposal) public proposals;

    function approve(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        string memory _assetAddress,
        address trustee,
        uint256 trusteeCount
    ) public override onlyBoringDAO returns (bool) {
        require(msg.sender == addrReso.key2address(BORINGDAO));
        bytes32 pid = keccak256(
            abi.encodePacked(_tunnelKey, _txid, _amount, _assetAddress)
        );
        if (proposals[pid].isExist == false) {
            // new proposal
            Proposal memory p = Proposal({
                tunnelKey: _tunnelKey,
                assetAddress: _assetAddress,
                txid: _txid,
                amount: _amount,
                creater: trustee,
                voteCount: 1,
                finished: false,
                isExist: true
            });
            proposals[pid] = p;
            proposals[pid].voteState[trustee] = true;
            emit NewMintProposal(_tunnelKey, _txid, _amount, _assetAddress, trustee, p.voteCount, trusteeCount);
        } else {
            // exist proposal
            Proposal storage p = proposals[pid];
            require(p.voteState[trustee] == false, "voted");
            if (p.finished) {
                return false;
            }
            p.voteCount = p.voteCount.add(1);
            p.voteState[trustee] = true;
            emit VoteMintProposal(_tunnelKey, _txid, _amount, _assetAddress, trustee, p.voteCount, trusteeCount);
        }
        Proposal storage p = proposals[pid];
        uint threshold = trusteeCount.mod(3) == 0 ? trusteeCount.mul(2).div(3) : trusteeCount.mul(2).div(3).add(1);
        if (p.voteCount >= threshold) {
            p.finished = true;
            emit VoteThroughMintProposal(_tunnelKey, _txid, _amount, _assetAddress, trustee, p.voteCount, trusteeCount);
            return true;
        } else {
            return false;
        }
    }

    modifier onlyBoringDAO {
        require(msg.sender == addrReso.key2address(BORINGDAO));
        _;
    }

    event NewMintProposal(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        string _assetAddress,
        address trustee,
        uint votedCount,
        uint256 trusteeCount
    );

    event VoteMintProposal(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        string _assetAddress,
        address trustee,
        uint votedCount,
        uint256 trusteeCount
    );

    event VoteThroughMintProposal(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        string _assetAddress,
        address trustee,
        uint votedCount,
        uint256 trusteeCount
    );
}
