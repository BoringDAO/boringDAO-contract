const Bor = artifacts.require("Bor");
const { toWei, fromWei } = require('web3-utils');
const {borMain, borRopsten} = require("../secret.json")

module.exports = async (deployer, network, accounts) => {
    console.log("network is ", network);
    let name, symbol, bor;
    if (network === "main") {
        bor = await Bor.at(borMain);
    } else {
        name = "BoringDAO";
        symbol = "BOR";
        await deployer.deploy(Bor, accounts[0]);
        const borNew = await Bor.deployed();
        console.log("bor address", borNew.address);
    }
}