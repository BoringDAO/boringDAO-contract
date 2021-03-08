// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/SafeDecimalMath.sol";

contract CrossLock is AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant CROSSER_ROLE = "CROSSER_ROLE";

    // ethToken => bscToken
    mapping(address => address) public supportToken;
    // mapping(address => mapping(address => uint256)) public lockAmount;

    // fee
    // leave ethereum
    mapping(address => uint256) public lockFeeRatio;
    mapping(address => uint256) public lockFeeAmount;
    // back ethereum
    mapping(address => uint256) public unlockFeeRatio;
    mapping(address => uint256) public unlockFeeAmount;
    //
    address public feeTo;

    mapping(string => bool) public txUnlocked;

    event Lock(
        address ethToken,
        address bscToken,
        address locker,
        address recipient,
        uint256 amount
    );
    event Unlock(
        address ethToken,
        address bscToken,
        address from,
        address recipient,
        uint256 amount,
        string txid
    );

    event FeeChange(
        address token,
        uint256 lockFeeAmount,
        uint256 lockFeeRatio,
        uint256 unlockFeeAmount,
        uint256 unlockFeeRatio
    );

    constructor(address _crosser, address _feeTo) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CROSSER_ROLE, _crosser);
        feeTo = _feeTo;
    }

    function addSupportToken(address ethTokenAddr, address bscTokenAddr)
        public
        onlyAdmin
    {
        require(
            supportToken[ethTokenAddr] == address(0),
            "Toke already Supported"
        );
        supportToken[ethTokenAddr] = bscTokenAddr;
    }

    function removeSupportToken(address ethTokenAddr) public onlyAdmin {
        require(supportToken[ethTokenAddr] != address(0), "Toke not Supported");
        delete supportToken[ethTokenAddr];
    }

    function addSupportTokens(
        address[] memory ethTokenAddrs,
        address[] memory bscTokenAddrs
    ) public {
        require(
            ethTokenAddrs.length == bscTokenAddrs.length,
            "Token length not match"
        );
        for (uint256 i; i < ethTokenAddrs.length; i++) {
            addSupportToken(ethTokenAddrs[i], bscTokenAddrs[i]);
        }
    }

    function removeSupportTokens(address[] memory addrs) public {
        for (uint256 i; i < addrs.length; i++) {
            removeSupportToken(addrs[i]);
        }
    }

    function setFee(
        address token,
        uint256 _lockFeeAmount,
        uint256 _lockFeeRatio,
        uint256 _unlockFeeAmount,
        uint256 _unlockFeeRatio
    ) public onlyAdmin {
        require(supportToken[token] != address(0), "Toke not Supported");
        require(_lockFeeRatio <= 1e18, " lock fee ratio not correct");
        require(_unlockFeeRatio <= 1e18, "unlock fee ratio not correct");
        lockFeeAmount[token] = _lockFeeAmount;
        lockFeeRatio[token] = _lockFeeRatio;
        unlockFeeAmount[token] = _unlockFeeAmount;
        unlockFeeRatio[token] = _unlockFeeRatio;
        emit FeeChange(token, _lockFeeAmount, _lockFeeRatio, _unlockFeeAmount, _unlockFeeRatio);
    }

    function calculateFee(
        address token,
        uint256 amount,
        uint256 crossType
    ) public view returns (uint256 feeAmount, uint256 remainAmount) {
        uint256 _feeMinAmount;
        uint256 _feeRatio;
        if (crossType == 0) {
            // leave ethereum
            _feeMinAmount = lockFeeAmount[token];
            _feeRatio = lockFeeRatio[token];
        } else {
            // back ethereum
            _feeMinAmount = unlockFeeAmount[token];
            _feeRatio = unlockFeeRatio[token];
        }
        feeAmount = _feeMinAmount.add(amount.multiplyDecimal(_feeRatio));
        remainAmount = amount.sub(feeAmount);
    }

    function lock(
        address token,
        address recipient,
        uint256 amount
    ) public onlySupportToken(token) {
        (uint256 feeAmount, uint256 remainAmount) =
            calculateFee(token, amount, 0);
        IERC20(token).safeTransferFrom(msg.sender, feeTo, feeAmount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), remainAmount);
        emit Lock(
            token,
            supportToken[token],
            msg.sender,
            recipient,
            remainAmount
        );
    }

    function unlock(
        address token,
        address from,
        address recipient,
        uint256 amount,
        string memory _txid
    ) public onlySupportToken(token) onlyCrosser whenNotUnlocked(_txid) {
        (uint256 feeAmount, uint256 remainAmount) =
            calculateFee(token, amount, 1);
        txUnlocked[_txid] = true;
        // lockAmount[token][recipient] = lockAmount[token][recipient].sub(amount);
        IERC20(token).safeTransfer(feeTo, feeAmount);
        IERC20(token).safeTransfer(recipient, remainAmount);
        emit Unlock(token, supportToken[token], from, recipient, remainAmount, _txid);
    }

    modifier onlySupportToken(address token) {
        require(supportToken[token] != address(0), "Lock::Not Support Token");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not admin");
        _;
    }

    modifier onlyCrosser {
        require(hasRole(CROSSER_ROLE, msg.sender), "caller is not crosser");
        _;
    }

    modifier whenNotUnlocked(string memory _txid) {
        require(txUnlocked[_txid] == false, "tx unlocked");
        _;
    }
}
