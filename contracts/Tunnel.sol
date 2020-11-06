// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interface/IAddressResolver.sol";
import "./interface/ITunnel.sol";
import "./ParamBook.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IBoringDAO.sol";
import "./interface/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IFeePool.sol";
import "./interface/IStakingRewardsFactory.sol";
import "./interface/IMintBurn.sol";
import "./interface/ITrusteeFeePool.sol";

contract Tunnel is Ownable, Pausable, ITunnel {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IAddressResolver addrResolver;
    bytes32 public constant BORINGDAO = "BoringDAO";
    // BTOKEN_BTC
    bytes32 public override oTokenKey;
    bytes32 public tunnelKey;
    bytes32 public constant MINT_FEE = "mint_fee";
    bytes32 public constant BURN_FEE = "burn_fee";
    bytes32 public constant MINT_FEE_TRUSTEE = "mint_fee_trustee";
    bytes32 public constant MINT_FEE_PLEDGER = "mint_fee_pledger";
    bytes32 public constant MINT_FEE_DEV = "mint_fee_dev";
    bytes32 public constant BURN_FEE_INSURANCE = "burn_fee_insurance";
    bytes32 public constant BURN_FEE_PLEDGER = "burn_fee_pledger";
    bytes32 public constant FEE_POOL = "FeePool";
    bytes32 public constant INSURANCE_POOL = "InsurancePool";
    bytes32 public constant DEV_ADDRESS = "DevUser";
    bytes32 public constant ADDRESS_BOOK = "AddressBook";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant BOR = "BOR";
    bytes32 public constant PLEDGE_RATE = "pledge_rate";
    bytes32 public constant NETWORK_FEE = "network_fee";
    bytes32 public constant PLEDGE_TOKEN = "PPT-BTC";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant TRUSTEE_FEE_POOL = "TrusteeFeePool";
    bytes32 public constant SATELLITE_POOL_FACTORY = "BTCSatellitePoolFactory";

    mapping(address => uint) public borPledgeInfo;
    // total pledge value in one token
    uint256 public totalPledgeBOR;

    struct PledgerInfo {
        uint256 amount;
        uint256 feeDebt;
    }

    struct RedeemUnlock {
        uint unlockTime;
        uint amount;
    }
    mapping(address=>RedeemUnlock[]) public unlockInfo;
    mapping(address=>uint256) public unlockNonce;

    uint256 public lockDuration = 86400;

    constructor(
        IAddressResolver _addrResolver,
        bytes32 _oTokenKey,
        bytes32 _tunnelKey
    ) public {
        addrResolver = _addrResolver;
        oTokenKey = _oTokenKey;
        tunnelKey = _tunnelKey;
        _pause();
    }

    // view
    function otokenMintBurn() internal view returns (IMintBurn) {
        return IMintBurn(addrResolver.requireAndKey2Address(oTokenKey, "Tunnel::otokenMintBurn: oToken contract not exist in Tunnel"));
    }

    function otokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(oTokenKey, "Tunnel::otokenERC20: oToken contract not exist in Tunnel"));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(BOR, "borERC20::borERC20: BOR contract not exist in Tunnel"));
    }

    function boringDAO() internal view returns (IBoringDAO) {
        return IBoringDAO(addrResolver.key2address(BORINGDAO));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrResolver.key2address(ORACLE));
    }

    function ppTokenMintBurn() internal view returns (IMintBurn) {
        return IMintBurn(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function ppTokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(addrResolver.key2address(FEE_POOL));
    }

    function trusteeFeePool() internal view returns (ITrusteeFeePool) {
        return ITrusteeFeePool(addrResolver.requireAndKey2Address(TRUSTEE_FEE_POOL, "Tunnel::trusteeFeePool is address(0)"));
    }

    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrResolver.key2address(PARAM_BOOK));
    }

    function getRate(bytes32 name) internal view returns (uint256) {
        return paramBook().params2(tunnelKey, name);
    }

    function satellitePoolFactory() internal view returns(IStakingRewardsFactory) {
        return IStakingRewardsFactory(addrResolver.key2address(SATELLITE_POOL_FACTORY));
    }

    function totalValuePledge() public override view returns (uint256) {
        uint256 borPrice = oracle().getPrice(BOR);
        return totalPledgeBOR.multiplyDecimal(borPrice);
    }

    function currentUnlock() public view returns(uint256, uint256) {
        uint current;
        uint newNonce;
        for (uint i=unlockNonce[msg.sender]; i<unlockInfo[msg.sender].length; i++) {
            if(block.timestamp >= unlockInfo[msg.sender][i].unlockTime) {
                current = current.add(unlockInfo[msg.sender][i].amount);
            } else {
                newNonce = i;
                break;
            }
        }
        return (current, newNonce);
    }

    // duration should bigger than lockDuration
    function setLockDuration(uint duration) public onlyOwner {
        lockDuration = duration;
    }

    function pledge(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        borPledgeInfo[account] = borPledgeInfo[account].add(amount);
        totalPledgeBOR = totalPledgeBOR.add(amount);
        // mint pledge token
        ppTokenMintBurn().mint(account, amount);
        feePool().notifyPTokenAmount(account, amount);
    }

    function redeem(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        require(
            ppTokenERC20().balanceOf(account) >= amount,
            "Tunnel::redeem: not enough pledge provider token"
        );
        require(borPledgeInfo[account] >= amount, "Tunnel:redeem: Not enough bor amount");
        borPledgeInfo[account] = borPledgeInfo[account].sub(amount);
        // send fee and burn ptoken
        // pledge token and fee
        // burn ptoken and tansfer back BOR
        lock(account, amount, block.timestamp.add(lockDuration));
        ppTokenMintBurn().burn(account, amount);
        feePool().withdraw(account, amount);
    }

    function lock(address account, uint amount, uint unlockTime) internal {
        unlockInfo[account].push(RedeemUnlock(unlockTime, amount));
    }

    function unlockPledgeBOR() public {
        (uint amount, uint n) = currentUnlock();
        unlockNonce[msg.sender] = n;
        totalPledgeBOR = totalPledgeBOR.sub(amount);
        borERC20().transfer(msg.sender, amount);
    }

    // when approved then issue
    function issue(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        //network fee
        uint networkFee = paramBook().params2(tunnelKey, NETWORK_FEE);
        // calculate fee
        uint256 mintFeeRation = getRate(MINT_FEE);
        uint256 mintFeeAmount = amount.multiplyDecimal(mintFeeRation);
        uint256 mintAmount = amount.sub(mintFeeAmount).sub(networkFee);
        otokenMintBurn().mint(account, mintAmount);
        // handle fee
        // trustee fee
        uint256 mintFeeTrusteeRatio = getRate(MINT_FEE_TRUSTEE);
        uint256 mintFeeTrusteeAmount = mintFeeAmount.multiplyDecimal(mintFeeTrusteeRatio).add(networkFee);
        otokenMintBurn().mint(address(trusteeFeePool()), mintFeeTrusteeAmount);
        trusteeFeePool().notifyReward(mintFeeTrusteeAmount);

        // fee to pledger
        uint256 mintFeePledgerRation = getRate(MINT_FEE_PLEDGER);
        uint256 mintFeePledgerAmount = mintFeeAmount.multiplyDecimal(
            mintFeePledgerRation
        );
        address feePoolAddress = address(feePool());
        otokenMintBurn().mint(feePoolAddress, mintFeePledgerAmount);
        feePool().notifyBTokenFeeAmount(mintFeePledgerAmount);


        // to developer team
        uint256 mintFeeDevRation = getRate(MINT_FEE_DEV);
        uint256 mintFeeDevAmount = mintFeeAmount.multiplyDecimal(
            mintFeeDevRation
        );
        address devAddress = addrResolver.key2address(DEV_ADDRESS);

        otokenMintBurn().mint(devAddress, mintFeeDevAmount);
    }


    function burn(address account, uint256 amount, string memory assetAddress) external override onlyBoringDAO{
        uint256 burnFeeAmountBToken = amount.multiplyDecimal(getRate(BURN_FEE));
        // convert to bor amount
        uint burnFeeAmount = oracle().getPrice(tunnelKey).multiplyDecimal(burnFeeAmountBToken).divideDecimal(oracle().getPrice(BOR));

        // insurance apart
        address insurancePoolAddress = addrResolver.key2address(INSURANCE_POOL);
        uint256 burnFeeAmountInsurance = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_INSURANCE)
        );


        // pledger apart
        uint256 burnFeeAmountPledger = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_PLEDGER)
        );
        borERC20().transferFrom(
            account,
            insurancePoolAddress,
            burnFeeAmountInsurance
        );
        //fee to feepool
        borERC20().transferFrom(
            account,
            address(feePool()),
            burnFeeAmountPledger
        );
        feePool().notifyBORFeeAmount(burnFeeAmountPledger);
        // otoken burn
        otokenMintBurn().burn(account, amount);
        emit BurnOToken(
            account,
            amount,
            boringDAO().getRandomTrustee(),
            assetAddress
        );
    }

    function totalTVL() public view returns(uint) {
        uint256 borTVL = totalValuePledge();
        uint satelliteTVL = satellitePoolFactory().satelliteTVL();
        return borTVL.add(satelliteTVL);
    }
    
    function pledgeRatio() public view returns(uint) {
        uint tvl = totalTVL();
        uint btokenValue = otokenERC20().totalSupply().multiplyDecimal(oracle().getPrice(tunnelKey));
        // todo
        if (btokenValue == 0) {
            return 0;
        }
        return tvl.divideDecimal(btokenValue);
    }

    function canIssueAmount() external override view returns (uint256) {
        // satellite pool tvl
        uint total = totalTVL();
        uint256 pledgeRate = paramBook().params2(tunnelKey, PLEDGE_RATE);
        uint256 canIssueValue = total.divideDecimal(pledgeRate);
        uint256 tunnelKeyPrice = oracle().getPrice(tunnelKey);
        return canIssueValue.divideDecimal(tunnelKeyPrice);
    }

    function unpause() public returns (bool) {
        if (totalPledgeBOR >= 3000e18) {
            _unpause();
        } 
        return paused();
    }

    modifier onlyBoringDAO {
        require(msg.sender == addrResolver.key2address(BORINGDAO));
        _;
    }

    event BurnOToken(
        address indexed account,
        uint256 amount,
        address proposer,
        string assetAddress
    );
}
