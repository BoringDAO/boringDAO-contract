const { assert } = require("chai");
const { isContractAddressInBloom, isTopic, toWei, fromWei } = require("web3-utils");

const MigratePool = artifacts.require("MigratePool");
const FakeWBTC = artifacts.require("FakeWBTC");
const OToken = artifacts.require("OToken");

const Web3Utils = require('web3-utils');
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

contract("MigratePool", async (accounts) => {
    describe("WBTC", async ()=> {
        it("Convert WBTC to oBTC", async () => {
            const mp = await MigratePool.deployed();
            const fwbtc = await FakeWBTC.deployed();
            const oBTC = await OToken.deployed();
            const supply1 = await oBTC.totalSupply();
            console.log("oBTC supply1: ", fromWei(supply1));
            await fwbtc.faucet({from: accounts[6]});
            await fwbtc.approve(mp.address, Web3Utils.toWei("1000")/10**10, {from: accounts[6]});
            await mp.deposit(Web3Utils.toWei("500")/10**10, {from: accounts[6]});
            const oBTCAmount = await oBTC.balanceOf(accounts[6]);
            assert.equal(fromWei(oBTCAmount), "498.5");
            const supply2 = await oBTC.totalSupply();
            console.log("oBTC supply2: ", fromWei(supply2));
        });
    });
});