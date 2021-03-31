const MintProposal = artifacts.require("MintProposal");
const AddressResolver = artifacts.require("AddressResolver");

const Web3Utils = require("web3-utils");
const {toWei, fromWei} = require("web3-utils");
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64);

contract("MintProposal", async (accounts) => {
    let mp, ar;
    before(async () => {
        ar = await AddressResolver.deployed();
        await ar.setAddress(toBytes32("BoringDAO"), accounts[0])
        mp = await MintProposal.deployed();
    });

    it("approve 2/3", async () => {
        await mp.approve(toBytes32("BTC"), "tx1", toWei("10"), "btcaddress1", accounts[1], 3);
        await mp.approve(toBytes32("BTC"), "tx1", toWei("10"), "btcaddress1", accounts[1], 3);
        await mp.approve(toBytes32("BTC"), "tx1", toWei("10"), "btcaddress1", accounts[1], 3);
    });
})