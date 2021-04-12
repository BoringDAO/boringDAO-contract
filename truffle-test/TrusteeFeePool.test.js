const { assert } = require("chai");
const { isTopic, toWei, fromWei } = require("web3-utils");

const TrusteeFeePool = artifacts.require("TrusteeFeePool");
const FakeTunnelBoringDAO = artifacts.require("FakeTunnelBoringDAO");
const Bor = artifacts.require("Bor");

contract("TrusteeFeePool", async (accounts) => {
    let tfp, fake, bor;
    before(async () => {
        bor = await Bor.deployed();
        tfp = await TrusteeFeePool.new(bor.address);
        fake = await FakeTunnelBoringDAO.new(tfp.address, bor.address);

        await tfp.setBoringDAO(fake.address);
        await tfp.setTunnel(fake.address);

        console.log("fake", fake.address);
    });

    it("notify reward", async () => {
        // first
        await bor.transfer(fake.address, toWei("20000"));
        await fake.enter(accounts[1]);
        await fake.enter(accounts[2]);
        // await fake.enter(accounts[3]);
        await fake.notifyReward(toWei("10"));
        const earned1 = await tfp.earned(accounts[1]);
        console.log("earned", fromWei(earned1));
        await fake.notifyReward(toWei("20"));
        const earned2 = await tfp.earned(accounts[1]);
        assert.equal(fromWei(earned2), "15");
        await fake.exit(accounts[1]);
        await fake.notifyReward(toWei("10"));
        const earned3 = await tfp.earned(accounts[1]);
        console.log("earned3", fromWei(earned3));
    });
});