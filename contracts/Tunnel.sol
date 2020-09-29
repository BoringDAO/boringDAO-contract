// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IAddressResolver.sol";
import "./interface/IBToken.sol";
import "./interface/ITunnel.sol";
import "./ParamBook.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IBoringDAO.sol";
import "./interface/IAddressBook.sol";
import "./interface/IOracle.sol";
import "./interface/IPToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IFeePool.sol";
import "./interface/IBORToken.sol";
import "./interface/IStakingRewardsFactory.sol";

contract Tunnel is Ownable, ITunnel {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IAddressResolver addrResolver;
    bytes32 public constant BORINGDAO = "BoringDAO";
    // BTOKEN_BTC
    bytes32 public bTokenKey;
    bytes32 public tunnelKey;
    bytes32 public constant MINT_FEE = "mint fee";
    bytes32 public constant BURN_FEE = "burn fee";
    bytes32 public constant MINT_FEE_TRUSTEE = "mint fee trustee";
    bytes32 public constant MINT_FEE_PLEDGER = "mint fee pledger";
    bytes32 public constant MINT_FEE_DEV = "mint fee dev";
    bytes32 public constant BURN_FEE_BURN = "burn fee burn";
    bytes32 public constant BURN_FEE_INSURANCE = "burn fee insurance";
    bytes32 public constant BURN_FEE_PLEDGER = "burn fee pledger";
    bytes32 public constant FEE_POOL = "FeePool";
    bytes32 public constant INSURANCE_POOL = "InsurancePool";
    bytes32 public constant DEV_ADDRESS = "DevUser";
    bytes32 public constant ADDRESS_BOOK = "AddressBook";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant BOR = "BOR";
    bytes32 public constant PLEDGE_RATE = "pledge rate";
    bytes32 public constant PLEDGE_TOKEN = "P-BTC-BOR";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant SATELLITE_POOL_FACTORY = "BTCSatellitePoolFactory";

    // pledge info
    mapping(address => uint256) public pledgeInfo;
    // total pledge value in one token
    uint256 totalPledgeBOR;

    struct PledgerInfo {
        uint256 amount;
        uint256 feeDebt;
    }

    constructor(
        IAddressResolver _addrResolver,
        bytes32 _bTokenKey,
        bytes32 _tunnelKey
    ) public {
        addrResolver = _addrResolver;
        bTokenKey = _bTokenKey;
        tunnelKey = _tunnelKey;
    }

    function btoken() internal view returns (IBToken) {
        return IBToken(addrResolver.requireAndKey2Address(bTokenKey, "bToken contract not exist in Tunnel"));
    }

    function btokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(bTokenKey, "bToken contract not exist in Tunnel"));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(BOR, "BOR contract not exist in Tunnel"));
    }

    function bor() internal view returns (IBORToken) {
        return IBORToken(addrResolver.key2address(BOR));
    }

    function boringDAO() internal view returns (IBoringDAO) {
        return IBoringDAO(addrResolver.key2address(BORINGDAO));
    }

    function addrBook() internal view returns (IAddressBook) {
        return IAddressBook(addrResolver.key2address(ADDRESS_BOOK));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrResolver.key2address(ORACLE));
    }

    function ptoken() internal view returns (IPToken) {
        return IPToken(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function pledgeTokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(addrResolver.key2address(FEE_POOL));
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

    // total pledage value 150%
    function totalValuePledge() public override view returns (uint256) {
        uint256 borPrice = oracle().getPrice(BOR);
        return totalPledgeBOR.multiplyDecimal(borPrice);
    }

    function pledge(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        pledgeInfo[account] = pledgeInfo[account].add(amount);
        totalPledgeBOR = totalPledgeBOR.add(amount);
        // mint pledge token
        ptoken().mintByTunnel(account, amount);
        feePool().notifyPTokenAmount(account, amount);
    }

    function redeem(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        require(
            pledgeTokenERC20().balanceOf(account) >= amount,
            "not enough pledge token"
        );
        require(pledgeInfo[account] >= amount, "Not enough amount");
        pledgeInfo[account] = pledgeInfo[account].sub(amount);
        totalPledgeBOR = totalPledgeBOR.sub(amount);
        // send fee and burn ptoken
        // pledge token and fee
        // burn ptoken and tansfer back BOR
        ptoken().burnByTunnel(account, amount);
        borERC20().transfer(account, amount);
        feePool().withdraw(account, amount);
    }

    // when approved then issue
    function issue(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        // calculate fee
        uint256 mintFeeRation = getRate(MINT_FEE);
        uint256 mintFeeAmount = amount.multiplyDecimal(mintFeeRation);
        uint256 mintAmount = amount.sub(mintFeeAmount);
        btoken().mintByTunnel(account, mintAmount);
        // handle fee
        // trustee fee
        uint256 mintFeeTrusteeRation = getRate(MINT_FEE_TRUSTEE);
        uint256 mintFeeTrustAmount = mintFeeAmount.multiplyDecimal(
            mintFeeTrusteeRation
        );
        uint256 trusteeCount = boringDAO().getTrusteeCount();
        uint256 feePerTrustee = mintFeeTrustAmount.div(trusteeCount);
        for (uint256 i = 0; i < trusteeCount; i++) {
            address trustee = boringDAO().getTrustee(i);
            btoken().mintByTunnel(trustee, feePerTrustee);
        }

        // fee to pledger
        uint256 mintFeePledgerRation = getRate(MINT_FEE_PLEDGER);
        uint256 mintFeePledgerAmount = mintFeeAmount.multiplyDecimal(
            mintFeePledgerRation
        );
        address feePoolAddress = address(feePool());
        btoken().mintByTunnel(feePoolAddress, mintFeePledgerAmount);
        feePool().notifyBTokenFeeAmount(mintFeePledgerAmount);


        // to developer team
        uint256 mintFeeDevRation = getRate(MINT_FEE_DEV);
        uint256 mintFeeDevAmount = mintFeeAmount.multiplyDecimal(
            mintFeeDevRation
        );
        address devAddress = addrResolver.key2address(DEV_ADDRESS);

        btoken().mintByTunnel(devAddress, mintFeeDevAmount);
    }

    // Just need a little randomness
    function getRandomTrustee() internal returns (address) {
        uint256 trusteeCount = boringDAO().getTrusteeCount();
        uint256 nextProposerIndex = uint256(
            keccak256(abi.encodePacked(now, block.difficulty))
        )
            .mod(trusteeCount);
        address trustee = boringDAO().getTrustee(nextProposerIndex);
        return trustee;
    }

    function burn(address account, uint256 amount) external override onlyBoringDAO{
        uint256 burnFeeAmountBToken = amount.multiplyDecimal(getRate(BURN_FEE));
        // convert to bor amount
        uint burnFeeAmount = oracle().getPrice(tunnelKey).multiplyDecimal(burnFeeAmountBToken).divideDecimal(oracle().getPrice(BOR));

        // insurance apart
        address insurancePoolAddress = addrResolver.key2address(INSURANCE_POOL);
        uint256 burnFeeAmountInsurance = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_INSURANCE)
        );

        // burn apart
        uint256 burnFeeAmountBurn = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_BURN)
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
        // burn
        bor().burnFrom(account, burnFeeAmountBurn);
        //fee to feepool
        borERC20().transferFrom(
            account,
            address(feePool()),
            burnFeeAmountPledger
        );
        feePool().notifyBORFeeAmount(burnFeeAmountPledger);
        // btoken burn
        btoken().burnByTunnel(account, amount);
        emit BurnBToken(
            account,
            amount,
            getRandomTrustee(),
            addrBook().eth2asset(account, tunnelKey)
        );
    }

    function totalTVL() public view returns(uint) {
        uint256 borTVL = totalValuePledge();
        uint satelliteTVL = satellitePoolFactory().satelliteTVL();
        return borTVL.add(satelliteTVL);
    }
    
    function pledgeRatio() public view returns(uint) {
        uint tvl = totalTVL();
        uint btokenValue = btokenERC20().totalSupply().multiplyDecimal(oracle().getPrice(tunnelKey));
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

    modifier onlyBoringDAO {
        require(msg.sender == addrResolver.key2address(BORINGDAO));
        _;
    }

    event BurnBToken(
        address indexed account,
        uint256 amount,
        address proposer,
        string assetAddress
    );
}
