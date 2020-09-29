// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPToken {
    function mintByTunnel(address to, uint256 amount) external;

    function burnByTunnel(address account, uint256 amount) external;

    function transferByTunnel(
        address from,
        address to,
        uint256 amount
    ) external;
}
