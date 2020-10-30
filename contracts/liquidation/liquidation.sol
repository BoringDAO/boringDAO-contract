// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interface/IAddressResolver.sol";
import "../interface/IPause.sol";
import "../interface/ILiquidate.sol";

interface IHasRole {
    function hashRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

contract Liquidation is AccessControl {

    using SafeMath for uint;

    bytes32 public constant TRUSTEE_ROLE = "TRUSTEE_ROLE";
    bytes32 public constant BORING_DAO = "BoringDAO";
    bytes32 public constant BBTC = "bBTC";
    address public coreDev;

    bool public shouldPauseDev;
    bool public shouldPauseTrustee;
    bool public systemPause;

    uint public confirmWithdrawAmount;

    IAddressResolver public addressReso;

    constructor(address _coreDev, address _addressReso) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        coreDev = _coreDev;
        addressReso = IAddressResolver(_addressReso);
    }

    function boringDAO() internal view returns (IPause) {
        return IPause(addressReso.requireAndKey2Address(BORING_DAO, "Liquidation::boringDAO contract not exist"));
    }

    function btoken() internal view returns (IPause) {
        return IPause(addressReso.requireAndKey2Address(BBTC, "Liquidation::bBTC contract not exist"));
    }

    // will pause the system
    function pause() public onlyPauser {
        if (msg.sender == coreDev) {
            shouldPauseDev = true;
        } else {
            shouldPauseTrustee = true;
        }
        if (shouldPauseDev && shouldPauseTrustee) {
            systemPause = true;
            // pause the system
            boringDAO().pause();
        }
    }

    function unpause() public onlyPauser {
        require(systemPause == true, "liquidation::should paused when call unpause()");
        if (msg.sender == coreDev) {
            shouldPauseDev = false;
        } else {
            shouldPauseTrustee = false;
        }
        if (shouldPauseDev != true && shouldPauseTrustee != true) {
            systemPause = false;
            boringDAO().unpause();
        }
    }

    function confirmWithdraw() public onlyTrustee {
        confirmWithdrawAmount= confirmWithdrawAmount.add(1); 
    }

    function withdraw(address target) public onlyPauser {
        uint trusteeCount = IHasRole(addressReso.requireAndKey2Address(BORING_DAO, "Liquidation::boringDAO contract not exist")).getRoleMemberCount(TRUSTEE_ROLE);
        uint threshold = trusteeCount.mod(3) == 0 ? trusteeCount.mul(2).div(3) : trusteeCount.mul(2).div(3).add(1);
        require(confirmWithdrawAmount >= threshold, "Liquidation:: not enough trustee confirm withdraw");
        ILiquidate(target).liquidate();
    }


    modifier onlyPauser {
        require(msg.sender == coreDev || IHasRole(address(boringDAO())).hashRole(TRUSTEE_ROLE, msg.sender), "caller is not a pauser");
        _;
    }

    modifier onlyTrustee {
        require(IHasRole(address(boringDAO())).hashRole(TRUSTEE_ROLE, msg.sender), "caller is not a trustee");
        _;
    }
}