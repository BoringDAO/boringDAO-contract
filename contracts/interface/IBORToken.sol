// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBORToken {
    // function cap() external view returns(uint);
    // function roCap() external view returns(uint);
    // function rebase(uint epoch, uint supplyDelta, bool positive) external returns(uint);
    function boringDAOMint(address to, uint256 amount) external;

    function totalCap() external view returns (uint256);

    function burn(uint amount) external;
    function burnFrom(address account, uint256 amount) external;
}
