const AddressBook = artifacts.require("AddressBook");
const AddressResolver = artifacts.require("AddressResolver");
const Liquidation = artifacts.require("Liquidation");
const OToken = artifacts.require("OToken");
const Bor = artifacts.require("Bor");
const BorBSC = artifacts.require("BorBSC");
const PPToken = artifacts.require("PPToken");
const StakingRewardsLockFactory = artifacts.require("StakingRewardsLockFactory");
const SatellitePoolFactory = artifacts.require("SatellitePoolFactory");
const Oracle = artifacts.require("Oracle");
const MigratePool = artifacts.require("MigratePool");

const FakeWETH = artifacts.require("FakeWETH");
const FakeUSDC = artifacts.require("FakeUSDC");
const FakeDAI = artifacts.require("FakeDAI")

const Web3Utils = require('web3-utils');

const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer, network, accounts) => {

    let weth, usdc, dai;
    if (network !== "main") {
        await deployer.deploy(FakeWETH, "WETH", "FWETH")
         weth = await FakeWETH.deployed();
        await deployer.deploy(FakeUSDC, "USDC", "FUSDC")
         usdc = await FakeUSDC.deployed();
        await deployer.deploy(FakeDAI, "DAI", "FDAI");
         dai = await FakeDAI.deployed();
    } else {
        weth = "0x";
        usdc = "0x";
        dai = "0x";
    }

    let bor;
    if (network === "bsc_testnet" || network === "bsc") {
        bor = await BorBSC.deployed();
        console.log("bor address", bor.address)
    } else {
        bor = await Bor.deployed();
    }

    const oBTC = await OToken.deployed();
    const ppToken = await PPToken.deployed();
    const addrResolver = await AddressResolver.deployed();

    const oracle = await Oracle.deployed();

    // await deployer.deploy(StakingRewardsLockFactory, bor.address, Math.floor(Date.now() / 1000)+60);
    // const srf = await StakingRewardsFactory.deployed();
    // await new Promise(r => setTimeout(r, 60000));
    let geneTs = Math.floor(Date.now() / 1000)+40;
    console.log("genTs", geneTs);
    await deployer.deploy(SatellitePoolFactory, bor.address, geneTs)
    const spf = await SatellitePoolFactory.deployed();
    await new Promise(r => setTimeout(r, 50000));

    // await addrResolver.setAddress(toBytes32("PoolFactory"), srf.address);
    await addrResolver.setAddress(toBytes32("BTCSatellitePoolFactory"), spf.address);    

    // await srf.deploy(oBTC.address);
    // await srf.deploy(pToken.address);
    let liqui = await Liquidation.deployed()

    // await spf.deploy(weth.address, liqui.address, oracle.address, toBytes32("FWETH"), 3600, 25, 75);
    // await spf.deploy(usdc.address, liqui.address, oracle.address, toBytes32("FUSDC"), 3600, 25, 75 );
    // await spf.deploy(dai.address, liqui.address, oracle.address, toBytes32("FDAI"), 3600, 25, 75);

    // // // deploy
    // await bor.transfer(srf.address, Web3Utils.toWei("2000"));
    // await srf.notifyRewardAmount(oBTC.address, 24*60*60, Web3Utils.toWei("1000"));
    // await srf.notifyRewardAmount(pToken.address, 24*60*60, Web3Utils.toWei("1000"));

    // await bor.transfer(spf.address, Web3Utils.toWei("3000"));
    // await spf.notifyRewardAmount(weth.address, 24*60*60, Web3Utils.toWei("1000"));
    // await spf.notifyRewardAmount(usdc.address, 24*60*60, Web3Utils.toWei("1000"));
    // await spf.notifyRewardAmount(dai.address, 24*60*60, Web3Utils.toWei("1000"));

    // let pool1 = await spf.poolByStakingToken(weth.address);
    // let pool2 = await spf.poolByStakingToken(usdc.address);
    // let pool3 = await spf.poolByStakingToken(dai.address);
    // console.log(network)
    // console.log("weth pool:", pool1);
    // console.log("usdc pool:", pool2);
    // console.log("dai pool:", pool3);

}