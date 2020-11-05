const AddressBook = artifacts.require("AddressBook");
const AddressResolver = artifacts.require("AddressResolver");
const BTokenSnapshot = artifacts.require("BTokenSnapshot");
const Bor = artifacts.require("Bor");
const PPToken = artifacts.require("PPToken");
const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");
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
    // if (network !== "main") {
    //      weth = await FakeWETH.deployed();
    //      usdc = await FakeUSDC.deployed();
    //      dai = await FakeDAI.deployed();
    // } else {
    //     weth = "0x";
    //     usdc = "0x";
    //     dai = "0x";
    // }

    const bBTC = await BTokenSnapshot.deployed();
    const bor = await Bor.deployed();
    const ppToken = await PPToken.deployed();
    const addrResolver = await AddressResolver.deployed();

    const oracle = await Oracle.deployed();

    // await deployer.deploy(StakingRewardsFactory, bor.address, Math.floor(Date.now() / 1000)+60);
    // const srf = await StakingRewardsFactory.deployed();
    // await new Promise(r => setTimeout(r, 60000));
    
    await deployer.deploy(SatellitePoolFactory, bor.address, Math.floor(Date.now() / 1000)+600)
    const spf = await SatellitePoolFactory.deployed();
    // await new Promise(r => setTimeout(r, 60000));

    // await addrResolver.setAddress(toBytes32("PoolFactory"), srf.address);
    await addrResolver.setAddress(toBytes32("BTCSatellitePoolFactory"), spf.address);    

    // await srf.deploy(bBTC.address);
    // await srf.deploy(pToken.address);

    // await spf.deploy(weth.address, accounts[0], oracle.address, toBytes32("FWETH"));
    // await spf.deploy(usdc.address, accounts[0], oracle.address, toBytes32("FUSDC"));
    // await spf.deploy(dai.address, accounts[0], oracle.address, toBytes32("FDAI"));

    // // // deploy
    // await bor.transfer(srf.address, Web3Utils.toWei("2000"));
    // await srf.notifyRewardAmount(bBTC.address, 24*60*60, Web3Utils.toWei("1000"));
    // await srf.notifyRewardAmount(pToken.address, 24*60*60, Web3Utils.toWei("1000"));

    // await bor.transfer(spf.address, Web3Utils.toWei("3000"));
    // await spf.notifyRewardAmount(weth.address, 24*60*60, Web3Utils.toWei("1000"));
    // await spf.notifyRewardAmount(usdc.address, 24*60*60, Web3Utils.toWei("1000"));
    // await spf.notifyRewardAmount(dai.address, 24*60*60, Web3Utils.toWei("1000"));

}