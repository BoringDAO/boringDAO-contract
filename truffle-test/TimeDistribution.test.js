const Bor = artifacts.require("Bor");
const TimeDistribution = artifacts.require("TimeDistribution");

const { assert } = require("chai");
const {toWei, fromWei} = require("web3-utils");

nowTs = () => {
    return Math.floor(Date.now() / 1000)+10;
}

contract("TimeDistribution", async (accounts) => {
    let bor, td;
    before(async () => {
        bor = await Bor.deployed();
        td = await TimeDistribution.deployed();
        await bor.approve(td.address, toWei("10000"));
        console.log("bor address", bor.address);
        console.log("td address", td.address);
    });
    it("add info", async () => {
        bor.transfer(td.address, toWei("3000"));
        await td.addInfo(accounts[1], toWei("1000"), nowTs(), nowTs()+300);
        await td.addInfo(accounts[2], toWei("1000"), nowTs(), nowTs()+300);
        await td.addInfo(accounts[3], toWei("1000"), nowTs(), nowTs()+300);
        await new Promise(r => setTimeout(r, 200000));
        await td.claim({from: accounts[1]});
        await td.claim({from: accounts[2]});
        await td.claim({from: accounts[3]});
    });

    it("change user", async () => {
        await td.changeUser(accounts[4], {from: accounts[1]});
        await td.changeUserAdmin(accounts[2], accounts[5]);
        const amount4 = await td.userTotalToken({from: accounts[4]});
        assert.equal(fromWei(amount4), "1000");
        const amount1 = await td.userTotalToken({from: accounts[1]});
        assert.equal(fromWei(amount1), "0");
    });

    it("pending calimed", async () => {
        const pending1 = await td.pendingClaim();
        assert.equal(fromWei(pending1), "0");
        const pending2 = await td.pendingClaim({from: accounts[4]});
        console.log("pending2", fromWei(pending2));
    });

    it("user total token", async () => {
        let amount = await td.userTotalToken({from: accounts[6]});
        assert.equal(fromWei(amount), "0");
    })

});