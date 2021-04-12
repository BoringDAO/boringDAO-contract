// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interface/IERC20Metadata.sol";
import "../interface/IOracle.sol";
import "../lib/SafeDecimalMath.sol";
import "../interface/IPair.sol";
import "../interface/ILiquidate.sol";

contract SatelliteCity is Ownable, Pausable, ILiquidateArray {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }
    // Info of each pool.
    struct PoolInfo {
        bool isSingle; // Single token or LP token.
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
    }

    IERC20 public borToken;
    // BOR tokens created per block.
    uint256 public borTokenPerBlock;
    // Bonus muliplier for early borToken makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    // IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BOR mining starts.
    uint256 public startBlock;
    address public dispatcher;
    uint256 public amountByMint;
    uint256 public tvl;
    IOracle public oracle;
    address public liquidation;

    bool public tvlSwitcher;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _borToken,
        uint256 _borTokenPerBlock,
        uint256 _startBlock,
        address _oracle,
        address _liquidation
    ) public {
        borToken = _borToken;
        borTokenPerBlock = _borTokenPerBlock;
        startBlock = _startBlock;
        oracle = IOracle(_oracle); 
        liquidation = _liquidation;
        tvlSwitcher = true;
    }

    function setTVLSwitcher(bool _status) external onlyOwner {
        tvlSwitcher = _status;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setDispatcher(address _account) external onlyOwner {
        dispatcher = _account;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(
        bool isSingle,
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                isSingle: isSingle,
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    // Update the given pool's borToken allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending tokens on frontend.
    function pendingBorToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 borTokenReward =
                multiplier.mul(borTokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accTokenPerShare = accTokenPerShare.add(
                borTokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 borTokenReward =
            multiplier.mul(borTokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            borTokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to SatelliteCity for BorToken allocation.
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeBorTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        if (tvlSwitcher) {
            tvl = calculateTVL();
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from SatelliteCity.
    function withdraw(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeBorTokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        if (tvlSwitcher) {
            tvl = calculateTVL();
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe borToken transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeBorTokenTransfer(address _to, uint256 _amount) internal {
        uint256 borTokenBal = borToken.allowance(dispatcher, address(this));
        if (_amount > borTokenBal) {
            if (borTokenBal > 0) {
                amountByMint = amountByMint.add(borTokenBal);
                borToken.transferFrom(dispatcher, _to, borTokenBal);
            }
        } else {
            amountByMint = amountByMint.add(_amount);
            borToken.transferFrom(dispatcher, _to, _amount);
        }
    }

    function liquidateArray(address account, uint256[] memory pids) public override onlyLiquidation {
        require(address(account) != address(0), "SatelliteCity: empty account");

        uint256 length = pids.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 pid = pids[i];
            PoolInfo storage pool = poolInfo[pid];
            IERC20 lpToken = pool.lpToken;
            uint256 bal = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(account, bal);
        }
    }

    function setTVL(uint256 _tvl) public onlyOwner {
        tvl = _tvl;
    }

    function calculateTVL() public view returns(uint256) {
        uint256 _tvl = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint lpAmount = pool.lpToken.balanceOf(address(this));
            if (pool.isSingle) {
                string memory symbol = IERC20Metadata(address(pool.lpToken)).symbol();
                uint8 decimals = IERC20Metadata(address(pool.lpToken)).decimals(); 
                uint price = oracle.getPrice(stringToBytes32(symbol));
                uint diff = uint256(18).sub(uint256(decimals));
                _tvl = _tvl.add(lpAmount.mul(10**(diff)).multiplyDecimal(price));
            } else {
                uint lpSupply = pool.lpToken.totalSupply();
                (uint112 _reserve0,,) = IPair(address(pool.lpToken)).getReserves();
                address token0 = IPair(address(pool.lpToken)).token0();
                // TODO: uint112 => uint256?
                uint amount = lpAmount.mul(uint256(_reserve0)).div(lpSupply);
                string memory symbol = IERC20Metadata(token0).symbol();
                uint8 decimals = IERC20Metadata(token0).decimals(); 
                uint price = oracle.getPrice(stringToBytes32(symbol));
                uint diff = uint256(18).sub(uint256(decimals));
                _tvl = _tvl.add(amount.mul(10**(diff)).multiplyDecimal(price).mul(2)); 
            }
        }
        return _tvl;
    }

    function satelliteTVL() public view returns (uint256) {
        return tvl;
    }

    // TODO: (test)
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        // bytes memory tempEmptyStringTest = bytes(source);
        // if (tempEmptyStringTest.length == 0) {
            // return 0x0;
        // }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function pause() public onlyLiquidation {
        _pause();
    }

    function unpause() public onlyLiquidation {
        _unpause();
    }

    function setLiquidation(address _liquidation) public onlyOwner {
        liquidation = _liquidation;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = IOracle(_oracle);
    }


    modifier onlyLiquidation {
        require(msg.sender == liquidation, "caller is not liquidator");
        _;
    }
}