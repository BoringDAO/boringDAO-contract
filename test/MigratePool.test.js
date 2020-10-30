const { assert } = require("chai");
const { isContractAddressInBloom, isTopic, toWei, fromWei } = require("web3-utils");

const MigratePool = artifacts.require("MigratePool");
const FakeWBTC = artifacts.require("FakeWBTC");
const BToken = artifacts.require("BToken");

const Web3Utils = require('web3-utils');
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

contract("MigratePool", async (accounts) => {
    describe("WBTC", async ()=> {
        it("Convert WBTC to bBTC", async () => {
            const mp = await MigratePool.deployed();
            const fwbtc = await FakeWBTC.deployed();
            const bBTC = await BToken.deployed();
            const supply1 = await bBTC.totalSupply();
            console.log("bBTC supply1: ", fromWei(supply1));
            await fwbtc.faucet({from: accounts[6]});
            await fwbtc.approve(mp.address, Web3Utils.toWei("1000")/10**10, {from: accounts[6]});
            await mp.deposit(Web3Utils.toWei("500")/10**10, {from: accounts[6]});
            const bBTCAmount = await bBTC.balanceOf(accounts[6]);
            assert.equal(fromWei(bBTCAmount), "498.5");
            const supply2 = await bBTC.totalSupply();
            console.log("bBTC supply2: ", fromWei(supply2));
        });
    });
});