// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IStableSwapOBTC {
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
    function fee() external view returns(uint256);
}