const AddressResolver = artifacts.require("AddressResolver");
const Liquidation = artifacts.require("Liquidation");
const FeePool = artifacts.require("FeePool");
const TrusteeFeePool = artifacts.require("TrusteeFeePool");
const InsurancePool = artifacts.require("InsurancePool");
const MintProposal = artifacts.require("MintProposal");
const BoringDAO =artifacts.require("BoringDAO");
const Tunnel = artifacts.require("Tunnel");
const OToken = artifacts.require("OToken");
const PPToken = artifacts.require("PPToken");
const Bor = artifacts.require("Bor");
const BorBsc = artifacts.require("BorBsc");
const {trusteesAddress, btcMultiSignAddress} = require("../trustee.json");

const Web3Utils = require('web3-utils');
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64);

module.exports = async (deployer, network, accounts) => {

    console.log("network", network);
    console.log("deploy account/oracle role", accounts[0]);
    if (network == "development") {
        console.log("trustee1", accounts[1]);
        console.log("trustee2", accounts[2]);
        console.log("trustee3", accounts[3]);
    }
    let bor;
    if(network === "bsc" || network === "bsc_testnet") {
        bor = await BorBsc.deployed();
    } else {
        bor = await Bor.deployed();
    }
    
    await deployer.deploy(AddressResolver);
    const addrResolver = await AddressResolver.deployed();

    await deployer.deploy(Liquidation, accounts[1], addrResolver.address);
    const liqui = await Liquidation.deployed();

    await deployer.deploy(FeePool, addrResolver.address, toBytes32("BTC"), toBytes32("oBTC"), toBytes32("oBTC-PPT"));

    await deployer.deploy(TrusteeFeePool, bor.address);

    await deployer.deploy(InsurancePool);

    await deployer.deploy(MintProposal, addrResolver.address);

    // BoringDAO
    // if (network === "develop")
    await deployer.deploy(BoringDAO, addrResolver.address, Web3Utils.toWei("60000"), accounts[0]);
    const boringDAO = await BoringDAO.deployed();

    // tunnel
    await deployer.deploy(Tunnel, addrResolver.address, toBytes32("oBTC"), toBytes32("BTC"));
    const tunnel = await Tunnel.deployed();

    // OToken
    await deployer.deploy(OToken, "BoringDAO BTC", "oBTC", 18, accounts[0]);
    const oBTC = await OToken.deployed();
    await oBTC.grantRole(toBytes32("MINTER_ROLE"), tunnel.address);
    await oBTC.grantRole(toBytes32("BURNER_ROLE"), tunnel.address);

    // PPToken
    await deployer.deploy(PPToken, "Pledge Provider Token BTC", "oBTC-PPT", 18, accounts[0]);
    const pptoken = await PPToken.deployed()
    await pptoken.grantRole(toBytes32("MINTER_ROLE"), tunnel.address);
    await pptoken.grantRole(toBytes32("BURNER_ROLE"), tunnel.address);

    // trusteeFeePool settings
    const trusteeFeePool = await TrusteeFeePool.deployed();
    // need trusteeFeePool when deploy BoringDAO
    await addrResolver.setAddress(toBytes32("TrusteeFeePool"), trusteeFeePool.address);
    await trusteeFeePool.setBoringDAO(boringDAO.address);
    await trusteeFeePool.setTunnel(tunnel.address);

    let trustees = [accounts[1], accounts[2], accounts[3]]
    if (network == "development") {
        boringDAO.addTrustees(trustees);
    } else {
        boringDAO.addTrustees(trusteesAddress);
    }

}
