// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BorFaucet {
    IERC20 public token;
    address private wallet;

    constructor(address _token, address _wallet) public {
        token = IERC20(_token);
        wallet = _wallet;
    }

    function get() public {
        token.transferFrom(wallet, msg.sender, 5e18);
    }
}