// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interface/IBoringDAO.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IAddressResolver.sol";
import "./interface/ITunnel.sol";
import "./interface/IBoring.sol";
import "./interface/IBORToken.sol";
import "./ParamBook.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IAddressBook.sol";
import "./interface/IMintProposal.sol";
import "./interface/IOracle.sol";

/**
@notice The BoringDAO contract is the entrance to the entire system, 
providing the functions of pledge BOR, redeem BOR, mint bBTC, and destroy bBTC
 */
contract BoringDAO is AccessControl, IBoringDAO {
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    uint public amountByMint;

    bytes32 public constant TRUSTEE_ROLE = "TRUSTEE_ROLE";
    bytes32 public constant GOV_ROLE = "GOV_ROLE";

    bytes32 public constant GOVER = "gover";
    bytes32 public constant BOR = "BOR";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant MINT_PROPOSAL = "MintProposal";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant ADDRESS_BOOK = "AddressBook";


    bytes32 public constant TUNNEL_MINT_FEE_RATE = "mint fee";

    IAddressResolver public addrResolver;

    // tunnels
    ITunnel[] public tunnels;

    constructor(IAddressResolver _addrResolver, address[] memory _trustees)
        public
    {
        // set up resolver
        addrResolver = _addrResolver;
        // set up trustee
        for (uint256 i = 0; i < _trustees.length; i++) {
            require(
                _trustees[i] != address(0),
                "Trustee Should not address(0)"
            );
            _setupRole(TRUSTEE_ROLE, _trustees[i]);
        }
        // set up gov
        _setupRole(GOV_ROLE, msg.sender);
    }

    // function
    function gover() internal view returns (address) {
        return addrResolver.key2address(GOVER);
    }

    function tunnel(bytes32 tunnelKey) internal view returns (ITunnel) {
        return ITunnel(addrResolver.key2address(tunnelKey));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.key2address(BOR));
    }

    function bor() internal view returns(IBORToken){
        return IBORToken(addrResolver.key2address(BOR));
    }


    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrResolver.key2address(PARAM_BOOK));
    }

    function addrBook() internal view returns (IAddressBook) {
        return IAddressBook(addrResolver.key2address(ADDRESS_BOOK));
    }

    function mintProposal() internal view returns (IMintProposal) {
        return IMintProposal(addrResolver.key2address(MINT_PROPOSAL));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrResolver.key2address(ORACLE));
    }
    /**
    @notice tunnelKey is byte32("symbol"), eg. bytes32("BTC")
     */
    function pledge(bytes32 _tunnelKey, uint256 _amount)
        public
        override
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
        whenContractExist(_tunnelKey)
    {
        tunnel(_tunnelKey).redeem(msg.sender, _amount);
    }

    function burnBToken(bytes32 _tunnelKey, uint256 amount)
        public
        override
        whenContractExist(_tunnelKey)
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
    ) public override onlyTrustee {
        // crate a mint proposal
        require(
            addrBook().asset2eth(_tunnelKey, _assetAddress) != address(0),
            "not assocated eth address"
        );
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
        uint256 canIssueAmount = tunnel(_tunnelKey).canIssueAmount();
        if (_amount > canIssueAmount) {
            // cant issue
            // event not enough pledge value
            emit NotEnoughPledgeValue(
                _tunnelKey,
                _txid,
                _amount,
                _assetAddress
            );
        } else {

            address to = addrBook().asset2eth(_tunnelKey, _assetAddress);
            // fee calculate in tunnel
            tunnel(_tunnelKey).issue(to, _amount);
            // mint bor reward
            uint256 mintFeeRate = paramBook().params2(
                _tunnelKey,
                TUNNEL_MINT_FEE_RATE
            );
            uint256 assetPrice = oracle().getPrice(_tunnelKey);
            uint256 borPrice = oracle().getPrice(BOR);
            uint256 factor_index = amountByMint.div(10000 * 10**18);
            uint256 factor = (4**factor_index).mul(10**18).div(5**factor_index);

            uint256 mintAmountInte = assetPrice
                .mul(2)
                .multiplyDecimalRound(_amount)
                .multiplyDecimalRound(mintFeeRate);
            uint256 mintAmount = mintAmountInte
                .multiplyDecimalRound(factor)
                .divideDecimalRound(borPrice);
            uint mintCap = bor().totalCap().mul(37).div(100);
            if (amountByMint.add(mintAmount) >= mintCap) {
                mintAmount = mintCap.sub(amountByMint);
                amountByMint = mintCap;
            } else {
                amountByMint = amountByMint.add(mintAmount);
            }
            IBORToken(address(borERC20())).boringDAOMint(to, mintAmount);
        }
    }

    function getTrustee(uint256 index) external override returns (address) {
        address addr = getRoleMember(TRUSTEE_ROLE, index);
        return addr;
    }

    function getTrusteeCount() external override returns (uint256) {
        return getRoleMemberCount(TRUSTEE_ROLE);
    }


    modifier onlyGov {
        require(hasRole(GOV_ROLE, msg.sender), "Caller is not gov");
        _;
    }

    modifier onlyTrustee {
        require(hasRole(TRUSTEE_ROLE, msg.sender), "Caller is not trustee");
        _;
    }

    modifier whenContractExist(bytes32 key) {
        require(
            address(addrResolver) != address(0),
            "Address Resolver not set"
        );
        require(
            addrResolver.key2address(key) != address(0),
            "Contract not exist"
        );
        _;
    }

    event NotEnoughPledgeValue(
        bytes32 indexed _tunnelKey,
        string indexed _txid,
        uint256 _amount,
        string assetAddress
    );
}
