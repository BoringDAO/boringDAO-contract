const AddressResolver = artifacts.require("AddressResolver");
const Tunnel = artifacts.require("Tunnel");
const BoringDAO = artifacts.require("BoringDAO");
const Bor = artifacts.require("Bor");

const { assert } = require("chai");
const Web3Utils = require("web3-utils");
const {toWei, fromWei} = require("web3-utils");
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64);

contract("Tunnel", async (accounts) => {
    let tunnel, ar, boringDAO, bor;
    before(async () => {
        tunnel = await Tunnel.deployed();
        ar = await AddressResolver.deployed();
        boringDAO = await BoringDAO.deployed();
        bor = await Bor.deployed();

        // active tunnel
        await bor.approve(boringDAO.address, Web3Utils.toWei("100000"));
        await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("100000"));
        await tunnel.unpause();

        await ar.setAddress(toBytes32("BoringDAO"), accounts[0])
    });

    it("ratio", async () => {
        const ratio = await tunnel.pledgeRatio();
        console.log(fromWei(ratio));
    });

    it("totalTVL", async () => {
        const tvl = await tunnel.totalTVL();
        assert.equal(fromWei(tvl), "15000000")
    })

    it("canIssueAmount", async () => {
        const canIssueAmount = await tunnel.canIssueAmount();
        assert.equal(fromWei(canIssueAmount), "2000");
    });
});