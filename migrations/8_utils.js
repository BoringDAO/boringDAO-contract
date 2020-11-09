const OToken = artifacts.require("OToken");
const Bor = artifacts.require("Bor");
const BoringDAO = artifacts.require("BoringDAO");
const Tunnel = artifacts.require("Tunnel");
const PPToken = artifacts.require("PPToken");
const StakingRewardsLockFactory = artifacts.require("StakingRewardsLockFactory");

const Web3Utils = require("web3-utils");
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer, network, accounts) => {
    if (network == "ropsten" || network == "kovan") {
    let obtc = await OToken.deployed();
    let pptoken = await PPToken.deployed();
    let fac = await StakingRewardsLockFactory.deployed();

    let pool1 = await fac.stakingRewardsInfoByStakingToken(obtc.address);
    let pool2 = await fac.stakingRewardsInfoByStakingToken(pptoken.address);
    console.log(network)
    console.log("obTC pool:", pool1);
    console.log("pptoken pool:", pool2);
    // console.log(toBytes32("BTC"))
    // console.log(Web3Utils.toWei("0.1"))

    let bor = await Bor.deployed()
    let bd = await BoringDAO.deployed();
    // let tunnel = await Tunnel.deployed();
    // await bor.approve(tunnel.address, Web3Utils.toWei("100"));
    // await bd.burnBToken(toBytes32("BTC"), Web3Utils.toWei("1"), "bcrt1q9xp4hdq79rnc0dev2pzyy4jk6qtgp6zess0539")

    await bor.approve(bd.address, Web3Utils.toWei("60000"))

    // console.log(toBytes32("BTC"))
    }

}