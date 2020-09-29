// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "./interface/IAddressResolver.sol";
import "./interface/IBORToken.sol";

contract BORToken is ERC20Capped, IBORToken {
    IAddressResolver addrReso;

    struct Checkpoint {
        uint32 fromBlock;
        uint   votes;
    }
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping (address => uint) public nonces;

    mapping (address => address) public delegates;
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance); 

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        IAddressResolver _addrResol
    ) public ERC20(_name, _symbol) ERC20Capped(_cap) {
        _mint(msg.sender, _cap.mul(63).div(100));
        addrReso = _addrResol;
    }

    function boringDAOMint(address to, uint256 amount) external override {
        require(
            msg.sender == addrReso.key2address("BoringDAO"),
            "Call is not boringDAO"
        );
        _mint(to, amount);
    }

    function totalCap() external view override returns(uint) {
        return super.cap();
    }

    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint amount;
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BOR::permit: invalid signature");
        require(signatory == owner, "BOR::permit: unauthorized");
        require(now <= deadline, "BOR::permit: signature expired");
        _approve(owner, spender, amount);

    }

    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BOR::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BOR::delegateBySig: invalid nonce");
        require(now <= expiry, "BOR::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "BOR::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
      uint32 blockNumber = uint32(block.number);

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }
      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _transfer(address sender, address recipient, uint amount) internal override {
        super._transfer(sender, recipient, amount);
        _moveDelegates(delegates[sender], delegates[recipient], amount);
    }

    
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function burn(uint256 amount) public override{
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public override{
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

}
