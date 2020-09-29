// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IAddressResolver.sol";
import "./interface/IFeePool.sol";


contract FeePool is ReentrancyGuard, IFeePool{
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant BOR = "BOR";
    bytes32 public  BTOKEN;
    bytes32 public PTOKEN;

    bytes32 public tunnelKey;
    IAddressResolver public addrReso;

    uint public borFeePerTokenStored;
    uint public bTokenFeePerTokenStored;

    mapping(address => uint) public userBORFee;
    mapping(address => uint) public userBORFeePaid;
    mapping(address => uint) public userBTokenFee;
    mapping(address => uint) public userBTokenFeePaid;



    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(IAddressResolver _addrReso, bytes32 _tunnelKey, bytes32 _btokenKey, bytes32 _ptokenKey) public {
        addrReso = _addrReso;
        tunnelKey = _tunnelKey;
        BTOKEN = _btokenKey;
        PTOKEN = _ptokenKey;
    }

    function bor() internal view returns (IERC20) {
        return IERC20(addrReso.requireAndKey2Address(BOR, "BOR contract is address(0) in FeePool"));
    }

    function btoken() internal view returns(IERC20) {
        return IERC20(addrReso.requireAndKey2Address(BTOKEN, "bToken contract is address(0) in FeePool"));
    }

    function ptoken() internal view returns(IERC20) {
        return IERC20(addrReso.requireAndKey2Address(PTOKEN, "bToken contract is address(0) in FeePool"));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function borFeePerToken() public view returns(uint) {
        return borFeePerTokenStored;
    }

    function bTokenFeePerToken() public view returns(uint) {
        return borFeePerTokenStored;
    }

    function earned(address account) public view override returns(uint, uint) {
        uint borFee = _balances[account].multiplyDecimal(borFeePerTokenStored.sub(userBORFeePaid[account])).add(userBORFee[account]);
        uint btokenFee = _balances[account].multiplyDecimal(bTokenFeePerTokenStored.sub(userBTokenFeePaid[account])).add(userBTokenFee[account]);
        return (borFee, btokenFee);
    }

    function getTotalFee() public view returns(uint, uint) {
        return (bor().balanceOf(address(this)), btoken().balanceOf(address(this)));
    }

    function notifyBORFeeAmount(uint amount) external override onlyTunnel {
        borFeePerTokenStored = borFeePerTokenStored.add(amount.divideDecimal(ptoken().totalSupply()));
    }

    function notifyBTokenFeeAmount(uint amount) external override onlyTunnel {

        bTokenFeePerTokenStored = bTokenFeePerTokenStored.add(amount.divideDecimal(ptoken().totalSupply()));
    }

    function notifyPTokenAmount(address account, uint amount) external override onlyTunnel {
        // first update account rewards
        (uint earnedBOR, uint earnedBToken) = earned(account);
        userBORFee[account] = earnedBOR; 
        userBTokenFee[account] = earnedBToken; 

        userBORFeePaid[account] = borFeePerTokenStored;
        userBTokenFeePaid[account] = bTokenFeePerTokenStored;

        _balances[account] = _balances[account].add(amount);
    }

    // function claimFeeByTunnel(address account) external onlyTunnel {
    //     _claimFee(account);
    // }

    function withdraw(address account, uint amount) external override onlyTunnel{
        _claimFee(account);
        _balances[account] = _balances[account].sub(amount);
        // _totalSupply = _totalSupply.sub(amount);
    }

    function claimFee() external {
        _claimFee(msg.sender);
    }

    function _claimFee(address account) internal {
        (uint earnedBOR, uint earnedBToken) = earned(account);

        bor().transfer(account, earnedBOR);
        userBORFee[account] = 0;
        userBORFeePaid[account] = borFeePerTokenStored;

        btoken().transfer(account, earnedBToken);
        userBTokenFee[account] = 0;
        userBTokenFeePaid[account] = bTokenFeePerTokenStored;

    }

    // modifier
    modifier onlyTunnel {
        require(
            msg.sender == addrReso.key2address(tunnelKey),
            "caller is not tunnel"
        );
        _;
    }


}