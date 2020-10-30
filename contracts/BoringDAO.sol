// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interface/IBoringDAO.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IAddressResolver.sol";
import "./interface/ITunnel.sol";
import "./interface/IBoring.sol";
import "./ParamBook.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IAddressBook.sol";
import "./interface/IMintProposal.sol";
import "./interface/IOracle.sol";
import "./interface/ICap.sol";

/**
@notice The BoringDAO contract is the entrance to the entire system, 
providing the functions of pledge BOR, redeem BOR, mint bBTC, and destroy bBTC
 */
contract BoringDAO is AccessControl, IBoringDAO, Pausable {
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    uint256 public amountByMint;

    bytes32 public constant TRUSTEE_ROLE = "TRUSTEE_ROLE";
    bytes32 public constant LIQUIDATION_ROLE = "LIQUIDATION_ROLE";
    bytes32 public constant GOV_ROLE = "GOV_ROLE";

    bytes32 public constant GOVER = "gover";
    bytes32 public constant BOR = "BOR";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant MINT_PROPOSAL = "MintProposal";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant ADDRESS_BOOK = "AddressBook";

    bytes32 public constant TUNNEL_MINT_FEE_RATE = "mint fee";
    bytes32 public constant NETWORK_FEE = "networkFee";

    IAddressResolver public addrReso;

    // tunnels
    ITunnel[] public tunnels;

    uint256 public mintCap;

    constructor(IAddressResolver _addrReso, address[] memory _trustees, uint _mintCap) public {
        // set up resolver
        addrReso = _addrReso;
        mintCap = _mintCap;
        // set up trustee
        for (uint256 i = 0; i < _trustees.length; i++) {
            _setupRole(TRUSTEE_ROLE, _trustees[i]);
        }
        // set up gov
        _setupRole(GOV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // function
    function gover() internal view returns (address) {
        return addrReso.key2address(GOVER);
    }

    function tunnel(bytes32 tunnelKey) internal view returns (ITunnel) {
        return ITunnel(addrReso.key2address(tunnelKey));
    }

    function btoken(bytes32 symbol) internal view returns (IERC20) {
        return IERC20(addrReso.key2address(symbol));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrReso.key2address(BOR));
    }

    function borCap() internal view returns (ICap) {
        return ICap(addrReso.key2address(BOR));
    }

    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrReso.key2address(PARAM_BOOK));
    }

    function addrBook() internal view returns (IAddressBook) {
        return IAddressBook(addrReso.key2address(ADDRESS_BOOK));
    }

    function mintProposal() internal view returns (IMintProposal) {
        return IMintProposal(addrReso.key2address(MINT_PROPOSAL));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrReso.key2address(ORACLE));
    }

    function getTrustee(uint256 index)
        external
        override
        view
        returns (address)
    {
        address addr = getRoleMember(TRUSTEE_ROLE, index);
        return addr;
    }

    function getTrusteeCount() external override view returns (uint256) {
        return getRoleMemberCount(TRUSTEE_ROLE);
    }

    function getRandomTrustee() public override view returns (address) {
        uint256 trusteeCount = getRoleMemberCount(TRUSTEE_ROLE);
        uint256 index = uint256(
            keccak256(abi.encodePacked(now, block.difficulty))
        )
            .mod(trusteeCount);
        address trustee = getRoleMember(TRUSTEE_ROLE, index);
        return trustee;
    }

    /**
    @notice tunnelKey is byte32("symbol"), eg. bytes32("BTC")
     */
    function pledge(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        require(
            borERC20().allowance(msg.sender, address(this)) >= _amount,
            "not allow enough bor"
        );

        borERC20().transferFrom(
            msg.sender,
            address(tunnel(_tunnelKey)),
            _amount
        );
        tunnel(_tunnelKey).pledge(msg.sender, _amount);
    }

    /**
    @notice redeem bor from tunnel
     */
    function redeem(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        tunnel(_tunnelKey).redeem(msg.sender, _amount);
    }

    function burnBToken(bytes32 _tunnelKey, uint256 amount)
        public
        override
        whenContractExist(_tunnelKey)
        whenTunnelNotPause(_tunnelKey)
    {
        require(
            bytes(addrBook().eth2asset(msg.sender, _tunnelKey)).length != 0,
            "not associated asset address"
        );
        tunnel(_tunnelKey).burn(msg.sender, amount);
    }

    /**
    @notice trustee will call the function to approve mint bToken
    @param _txid the transaction id of bitcoin
    @param _amount the amount to mint, 1BTC = 1bBTC = 1*10**18 weibBTC
    @param _assetAddress user's btc address
     */
    function approveMint(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        string memory _assetAddress
    ) public override whenNotPaused whenTunnelNotPause(_tunnelKey) onlyTrustee {
        // crate a mint proposal
        require(
            addrBook().asset2eth(_tunnelKey, _assetAddress) != address(0),
            "not assocated eth address"
        );
        uint256 canIssueAmount = tunnel(_tunnelKey).canIssueAmount();
        if (_amount.add(btoken(bytes32("bBTC")).totalSupply()) > canIssueAmount) {
            emit NotEnoughPledgeValue(
                _tunnelKey,
                _txid,
                _amount,
                _assetAddress,
                msg.sender
            );
            return;
        }
        uint256 trusteeCount = getRoleMemberCount(TRUSTEE_ROLE);
        bool shouldMint = mintProposal().approve(
            _tunnelKey,
            _txid,
            _amount,
            _assetAddress,
            msg.sender,
            trusteeCount
        );
        if (!shouldMint) {
            return;
        }
        // vote processed, to check pledge token value
        address to = addrBook().asset2eth(_tunnelKey, _assetAddress);
        // fee calculate in tunnel
        tunnel(_tunnelKey).issue(to, _amount);

        uint borMintAmount = calculateMintBORAmount(_tunnelKey, _amount);
        if(borMintAmount != 0) {
            amountByMint = amountByMint.add(borMintAmount);
            borERC20().transfer(to, borMintAmount);
        }
    }

    function calculateMintBORAmount(bytes32 _tunnelKey, uint _amount) public view returns (uint) {
        if (amountByMint >= mintCap) {
            return 0;
        }
        uint256 assetPrice = oracle().getPrice(_tunnelKey);
        uint256 borPrice = oracle().getPrice(BOR);
        uint256 reductionTimes = amountByMint.div(10_000e18);
        uint256 mintFeeRate = paramBook().params2(
            _tunnelKey,
            TUNNEL_MINT_FEE_RATE
        );
        // for decimal calculation, so mul 1e18
        uint256 reductionFactor = (4**reductionTimes).mul(1e18).div(5**reductionTimes);
        uint networkFee = paramBook().params2(_tunnelKey, NETWORK_FEE);
        uint baseAmount = _amount.multiplyDecimalRound(mintFeeRate).add(networkFee);
        uint borAmount = assetPrice.mul(2).multiplyDecimalRound(baseAmount).multiplyDecimalRound(reductionFactor).divideDecimalRound(borPrice);
        if (amountByMint.add(borAmount) >= mintCap) {
            borAmount = mintCap.sub(amountByMint);
        }
        return borAmount;
    }

    function pause() public onlyLiquidation {
        _pause();
    }

    function unpause() public onlyLiquidation {
        _unpause();
    }

    modifier onlyGov {
        require(hasRole(GOV_ROLE, msg.sender), "Caller is not gov");
        _;
    }

    modifier onlyTrustee {
        require(hasRole(TRUSTEE_ROLE, msg.sender), "Caller is not trustee");
        _;
    }

    modifier onlyLiquidation {
        require(
            hasRole(LIQUIDATION_ROLE, msg.sender),
            "Caller is not liquidation contract"
        );
        _;
    }

    modifier whenContractExist(bytes32 key) {
        require(
            addrReso.key2address(key) != address(0),
            "Contract not exist"
        );
        _;
    }

    modifier whenTunnelNotPause(bytes32 _tunnelKey) {
        address tunnelAddress = addrReso.requireAndKey2Address(_tunnelKey, "tunnel not exist");
        require(IPaused(tunnelAddress).paused() == false, "tunnel is paused");
        _;
    }

    event NotEnoughPledgeValue(
        bytes32 indexed _tunnelKey,
        string indexed _txid,
        uint256 _amount,
        string assetAddress,
        address trustee
    );
}

interface IPaused {
    function paused() external view returns (bool);
}
