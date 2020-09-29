// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBToken {
    function mintByTunnel(address to, uint amount) external;
    function burnByTunnel(address account, uint amount) external;
    function transferByTunnel(address from, address to, uint amount) external;
}