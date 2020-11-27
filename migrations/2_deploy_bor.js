const Bor = artifacts.require("Bor");
const BorBSC = artifacts.require("BorBSC");
const { toWei, fromWei } = require('web3-utils');
const {borMain, borRopsten} = require("../secret.json")

module.exports = async (deployer, network, accounts) => {
    console.log("network is ", network);
    let name, symbol, bor;
    if (network === "main") {
        bor = await Bor.at(borMain);
    } else if (network === "bsc_testnet" || network === "bsc") {
        name = "BoringDAO";
        symbol = "BOR";
        await deployer.deploy(BorBSC, name, symbol, accounts[0]);
        const bor = await BorBSC.deployed();
        await bor.mint(accounts[0], toWei("20000"));
        console.log("borBSC address", bor.address);
    } else {
        name = "BoringDAO";
        symbol = "BOR";
        await deployer.deploy(Bor, accounts[0]);
        const borNew = await Bor.deployed();
        console.log("bor address", borNew.address);
    }
}