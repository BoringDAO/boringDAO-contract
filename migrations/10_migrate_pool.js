const { toWei } = require("web3-utils");

const MigratePool = artifacts.require("MigratePool");
const FakeWBTC = artifacts.require("FakeWBTC");
const FakeRenBTC = artifacts.require("FakeRenBTC");
const OToken = artifacts.require("OToken");

const Web3Utils = require("web3-utils")
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer, network, account) => {
    await deployer.deploy(FakeWBTC, "WBTC", "WBTC")
    await deployer.deploy(FakeRenBTC, "RenBTC", "RenBTC")

    let oBTC = await OToken.deployed();
    let wBTC = await FakeWBTC.deployed();
    let renBTC = await FakeRenBTC.deployed();

    await deployer.deploy(MigratePool, wBTC.address, oBTC.address, toWei("0.96"), 10)
    let mp = await MigratePool.deployed();

    // 
    await oBTC.grantRole(toBytes32("MINTER_ROLE"), mp.address);
}