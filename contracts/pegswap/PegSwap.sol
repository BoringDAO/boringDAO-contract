// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IPegSwapPair.sol";

contract PegSwap is Ownable {
    using SafeMath for uint;

    // origin token address => pair address
    // example: dai => pair(token0=dai, token1=borDAI)
    mapping(address => address) public pairs;

    function getPair(address token) public view onlySupportToken(token) returns (address) {
        return pairs[token];
    }

    function addPair(address token, address pair) public onlyOwner {
        require(pairs[token] == address(0), "Toke already supported");
        pairs[token] = pair;
    }

    function removePair(address token) public onlyOwner {
        require(pairs[token] != address(0), "Toke not supported");
        delete pairs[token];
    }

    function addLiquidity(
        address token0,
        uint amount,
        address to
    ) public onlySupportToken(token0) returns(uint256 liquidity) {
        address pair = getPair(token0);
        IERC20(token0).transferFrom(msg.sender, pair, amount);
        liquidity = IPegSwapPair(pair).mint(to);
    }

    function removeLiquidity(
        address token0,
        uint256 liquidity,
        address to
    ) public onlySupportToken(token0) returns(uint256 amount0, uint256 amount1) {
        address pair = getPair(token0);
        IERC20(pair).transferFrom(msg.sender, pair, liquidity);
        (amount0, amount1) = IPegSwapPair(pair).burn(to);
    }

    function swap(address token0, uint256 amountIn, address to) public onlySupportToken(token0) {
        require(amountIn > 0, "Input must be greater than 0");
        address pair = getPair(token0);
        address token1 = IPegSwapPair(pair).token1(); 

        // transfer bor-erc20 token to pair address
        IERC20(token1).transferFrom(msg.sender, pair, amountIn);
        IPegSwapPair(pair).swap(to); 
    }

    modifier onlySupportToken(address token) {
        require(pairs[token] != address(0), "Not support this token");
        _;
    }
}