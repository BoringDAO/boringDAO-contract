
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interface/IPair.sol";

contract FakePair is ERC20 {

    address public token0;
    address public token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

    constructor(address _token0, address _token1) public ERC20("LP Token", "BLP") {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (_reserve0, _reserve1, 0);
    }

    function faucet() public {
        _mint(msg.sender, 100 * 1e18);
        _reserve0 = _reserve0 + 100 * 1e8; // decimals: 8
        _reserve1 = _reserve1 + 100 * 1e18; // decimals: 18
    }
}
