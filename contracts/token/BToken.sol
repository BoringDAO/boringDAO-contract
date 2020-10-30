  
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseToken.sol";

contract BTokenOld is BaseToken {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        address admin
    ) public BaseToken(name_, symbol_, decimal_, admin) {}
}