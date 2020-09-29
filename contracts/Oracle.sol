// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IOracle.sol";

contract Oracle is AccessControl, IOracle {
    bytes32 public ORACLE_ROLE = keccak256("ORACLE_ROLE");

    mapping(bytes32 => uint256) public priceOf;

    constructor() public {
        _setupRole(ORACLE_ROLE, msg.sender);
    }

    function setPrice(bytes32 _symbol, uint256 _price) public override {
        require(hasRole(ORACLE_ROLE, msg.sender), "Caller is not a oracle");
        priceOf[_symbol] = _price;
    }

    function getPrice(bytes32 _symbol) public override view returns (uint256) {
        require(priceOf[_symbol] != uint256(0), "price is not exist");
        return priceOf[_symbol];
    }
}
