const { assert } = require("chai");
const { toWei, fromWei } = require("web3-utils");

const TimeDistribution = artifacts.require("TimeDistribution");
const Bor = artifacts.require("Bor");

module.exports = async (deployer, network, accounts) => {
    // if (network === "development") {
        let bor = await Bor.deployed();
        // await deployer.deploy(TimeDistribution, bor.address, accounts[0]);
        // let td = await TimeDistribution.deployed();
        let td = await TimeDistribution.at("0x1cca27fe5A384cB76Ab3183B0565D22Acab3F997");
        await bor.approve(td.address, toWei("4000"));
        // let addressArray = ["0xd936f1D54A62e9ac7C6a2dF8992A33f2bb48594D", "0xbcFc003FBe94Ec945e9e72eA7a6DBC711205E9cC", accounts[1], accounts[2], accounts[3], accounts[4]]
        // let amountsArray = [toWei("600"), toWei("1200"), toWei("700"), toWei("22222"), toWei("1333"), toWei("2342")]
        // let beginTsArray = [1604911015, 1604911015, 1604911015, 1604911015, 1604911015, 1604911015]
        // let endTsArray =   [1604911015+24*60*60, 1604911015+24*60*60, 1604911015+24*60*60, 1604911015+24*60*60, 1604911015+24*60*60, 1604911015+24*60*60]
        // console.log(addressArray.length)
        // console.log(amountsArray.length)
        // console.log(beginTsArray.length)
        // console.log(endTsArray.length)
        // // assert(addressArray.length == amountsArray.length == beginTsArray.length == endTsArray.length)
        // await td.addMultiInfo(addressArray, amountsArray, beginTsArray, endTsArray);

        // await td.addInfo("0xED48d097Dfec35741850A7F40F611f0d4711Ca0f", toWei("1000"), 1604917017, 1604911015+24*60*60)
        await td.addInfo("0x9ce864ad7d1c19746a1438F3803D306fEd158275", toWei("1000"), 1605076675, 1605075386+2*24*60*60)

        // console.log(accounts[1], accounts[2], accounts[3], accounts[4])

        // let pending = await td.pendingClaim({from: accounts[1]});
        // console.log("pending", fromWei(pending));
        
    // }
}