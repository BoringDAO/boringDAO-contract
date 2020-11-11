const StakingRewardsLockFactory = artifacts.require("StakingRewardsLockFactory");
const Bor = artifacts.require("Bor");
const OToken = artifacts.require("OToken");
const PPToken = artifacts.require("PPToken");
const {toWei, fromWei} = require("web3-utils");
const Web3Utils = require("web3-utils");
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer, network, accounts) => {
    const bor = await Bor.deployed();
    const pptoken = await PPToken.deployed();
    const oBTC = await OToken.deployed();

    // let geneTs = Math.floor(Date.now() / 1000)+40;
    // console.log("genTs", geneTs);
    // await deployer.deploy(StakingRewardsLockFactory, bor.address, geneTs);
    const srf = await StakingRewardsLockFactory.deployed();
    // await new Promise(r => setTimeout(r, 40000));

    // await srf.deploy(oBTC.address, 3600, 25, 75);
    // await srf.deploy(pptoken.address, 3600, 25, 75);
    
    await bor.transfer(srf.address, toWei("300"));
    await srf.notifyRewardAmount(oBTC.address, 60*60, toWei("150"));
    await srf.notifyRewardAmount(pptoken.address, 60*60, toWei("150"));

}