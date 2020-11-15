const { toWei } = require("web3-utils");

const MigratePool = artifacts.require("MigratePool");
const FakeWBTC = artifacts.require("FakeWBTC");
const FakeRenBTC = artifacts.require("FakeRenBTC");
const OToken = artifacts.require("OToken");
const Oracle = artifacts.require("Oracle");

const Web3Utils = require("web3-utils")
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer, network, accounts) => {
    // await deployer.deploy(FakeWBTC, "WBTC", "WBTC")
    // await deployer.deploy(FakeRenBTC, "RenBTC", "RenBTC")

    // let oBTC = await OToken.deployed();
    // let wBTC = await FakeWBTC.deployed();
    // let renBTC = await FakeRenBTC.deployed();

    // await deployer.deploy(MigratePool, wBTC.address, oBTC.address, toWei("0.96"), 10)
    // let mp = await MigratePool.deployed();

    // // 
    // await oBTC.grantRole(toBytes32("MINTER_ROLE"), mp.address);
    // let oracle = await Oracle.at("0x32ba2f5D890b848e0D8911010DCDa6B9F9240130");
    // console.log(toBytes32("BTC"))
    // console.log(toWei("15000.12"))

    //  towei = (n) => Web3Utils.toWei(n) 
    // let symbols = ["BOR", "YFI", "SNX", "LINK", "FWETH", "FUSDC", "FDAI", "BTC"].map(toBytes32);
    // let prices = ["160", "10000", "4", "11", "480", "1.5", "1.5", "15000"].map(towei);
    // await oracle.setMultiPrice(symbols, prices, {from: accounts[1]});

    console.log(toBytes32("ORACLE_ROLE"))
}