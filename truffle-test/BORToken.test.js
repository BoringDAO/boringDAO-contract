const Bor = artifacts.require("Bor");

const { assert } = require('chai');
const Web3Utils = require('web3-utils');
const {toWei, fromWei} = require("web3-utils");

contract("Bor", async (accounts) => {
    let bor;
    before( async () => {
        bor = await Bor.deployed();
    });

    it("normal transfer", async () => {
        await bor.transfer(accounts[3], toWei("3333"))
        await bor.transfer(accounts[3], toWei("3333"))
        await bor.transfer(accounts[3], toWei("3333"))
        await bor.transfer(accounts[3], toWei("3333"))
    })

    it("should delegate ok", async () => {
        await bor.delegate(accounts[1]);
        const votes = await bor.getCurrentVotes(accounts[1]);
        assert.equal(fromWei(votes), "182668");
    });


    it("transfer after delegated", async () => {
        await bor.transfer(accounts[2], toWei("3001"));
        await bor.transfer(accounts[2], toWei("3001"));
        await bor.transfer(accounts[2], toWei("3001"));
        const votes = await bor.getCurrentVotes(accounts[1]);
        assert.equal(fromWei(votes), "173665");
    });

    it("approve gas", async () => {
        await bor.approve(accounts[2], toWei("4000"))
    })
})

