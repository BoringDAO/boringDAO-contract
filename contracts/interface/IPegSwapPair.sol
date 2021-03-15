// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPegSwapPair {
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function token1() external returns (address);
    function swap(address to) external;
}