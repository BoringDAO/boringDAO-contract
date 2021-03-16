// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IOracle.sol";
import "./interface/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract OracleV2 is AccessControl, IOracle {
    using SafeMath for uint256;

    bytes32 public ORACLE_ROLE = "ORACLE_ROLE";
    bytes32 public CHANGER_ROLE = "CHANGER_ROLE";

    uint256 public diffDecimal=10;

    mapping(bytes32 => uint256) public priceOf;
    mapping(bytes32 => address) public outer;  

    constructor() public {
        _setupRole(ORACLE_ROLE, msg.sender);
        _setupRole(CHANGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setOuter(bytes32 name, address oracle) external onlyChanger {
        outer[name] = oracle;
    }

    function setPrice(bytes32 _symbol, uint256 _price) external override  onlyOracle{
        priceOf[_symbol] = _price;
    }

    function setDiffDecimal(uint diff) external onlyChanger {
        diffDecimal = diff;
    }

    function setMultiPrice(bytes32[] memory _symbols, uint[] memory _prices) external onlyOracle{
        require(_symbols.length == _prices.length);
        for (uint i=0; i < _symbols.length; i++) {
            priceOf[_symbols[i]] = _prices[i];
        }
    }

    function getPrice(bytes32 _symbol) external override view returns (uint256) {
        if (outer[_symbol] != address(0)) {
            (, int price, , , ) = AggregatorV3Interface(outer[_symbol]).latestRoundData();
            require(price>0, "price<=0, error");
            return uint(price).mul(10**diffDecimal);
        } else {
            require(priceOf[_symbol] != uint256(0), "price is not exist");
            return priceOf[_symbol];
        }
    }

    modifier onlyOracle {
        require(hasRole(ORACLE_ROLE, msg.sender), "Caller is not a oracle");
        _;
    }

    modifier onlyChanger {
        require(hasRole(CHANGER_ROLE, msg.sender), "Caller is not a changer");
        _;
    }
}
