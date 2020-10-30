const AddressResolver = artifacts.require("AddressResolver");
const FeePool = artifacts.require("FeePool");
const InsurancePool = artifacts.require("InsurancePool");
const MintProposal = artifacts.require("MintProposal");
const BoringDAO =artifacts.require("BoringDAO");
const Tunnel = artifacts.require("Tunnel");
// const BToken = artifacts.require("BToken");
const BTokenSnapshot = artifacts.require("BTokenSnapshot");
const PPToken = artifacts.require("PPToken");
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
    
    await deployer.deploy(AddressResolver);
    const addrResolver = await AddressResolver.deployed();

    await deployer.deploy(FeePool, addrResolver.address, toBytes32("BTC"), toBytes32("bBTC"), toBytes32("PPT-BTC"));

    await deployer.deploy(InsurancePool);

    await deployer.deploy(MintProposal, addrResolver.address);

    // BoringDAO
    // if (network === "develop")
    let trustees = [accounts[1], accounts[2], accounts[3]]
    if (network == "development") {
        await deployer.deploy(BoringDAO, addrResolver.address, trustees, Web3Utils.toWei("60000"));
    } else {
        await deployer.deploy(BoringDAO, addrResolver.address, trusteesAddress, Web3Utils.toWei("60000"));
    }

    // tunnel
    await deployer.deploy(Tunnel, addrResolver.address, toBytes32("bBTC"), toBytes32("BTC"));
    const tunnel = await Tunnel.deployed();

    // BToken
    // await deployer.deploy(BToken, "Boring BTC", "bBTC", toBytes32("BTC"), addrResolver.address);
    // const bBTC = await BToken.deployed();
    // await bBTC.grantRole(toBytes32("MINTER_ROLE"), tunnel.address);
    // await bBTC.grantRole(toBytes32("BURNER_ROLE"), tunnel.address);

    // BTokenSnapshot
    await deployer.deploy(BTokenSnapshot, "Boring BTC", "bBTC", 18, accounts[0]);
    const bBTC = await BTokenSnapshot.deployed();
    await bBTC.grantRole(toBytes32("MINTER_ROLE"), tunnel.address);
    await bBTC.grantRole(toBytes32("BURNER_ROLE"), tunnel.address);

    // PPToken
    await deployer.deploy(PPToken, "Pledge Provider Token", "PPT-BTC", 18, accounts[0]);
    const pptoken = await PPToken.deployed()
    await pptoken.grantRole(toBytes32("MINTER_ROLE"), tunnel.address);
    await pptoken.grantRole(toBytes32("BURNER_ROLE"), tunnel.address);

    


}
