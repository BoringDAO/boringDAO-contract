const BoringDAO = artifacts.require('BoringDAO')
const Bor = artifacts.require("Bor");
const PPToken = artifacts.require("PPToken");
const Tunnel = artifacts.require("Tunnel");
const AddressResolver = artifacts.require("AddressResolver");
const AddressBook = artifacts.require("AddressBook")
const OToken = artifacts.require("OToken");
const Oracle = artifacts.require("Oracle");
const FeePool = artifacts.require("FeePool");
const StakingRewardsLockFactory = artifacts.require("StakingRewardsLockFactory");
const Web3Utils = require('web3-utils');



const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

contract("BoringDAO Pledge/Redeem", async (accounts) => {
    let boringDAO, bor, addrReso, tunnel, ppToken;
    before(async () => {
        boringDAO = await BoringDAO.deployed();
        bor = await Bor.deployed();
        addrReso = await AddressResolver.deployed();
        ppToken = await PPToken.deployed();
        tunnel = await Tunnel.deployed();
        // addrBook = await AddressBook.deployed();
        // btoken = await BToken.deployed();
        // oracle = await Oracle.deployed();
        // feePool = await FeePool.deployed();
        // satellitePoolFactory = await StakingRewardsFactory.deployed();
    });

    it("tunnel's pledge bor 0 and pause", async () => {
        const pledgeBalance = await bor.balanceOf(tunnel.address);
        assert.equal(Web3Utils.fromWei(pledgeBalance), "0");
        const totalPledgeBOR = await tunnel.totalPledgeBOR();
        assert.equal(Web3Utils.fromWei(totalPledgeBOR), "0");
        const isPaused = await tunnel.paused();
        assert.equal(isPaused, true);
    });

    it("active tunnel", async () => {
        await bor.approve(boringDAO.address, Web3Utils.toWei("3000"));
        await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("2000"));
        const con1 = await tunnel.unpause.call();
        assert.equal(con1, true)
        await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("1000"));
        const con2 = await tunnel.unpause.call();
        assert.equal(con2, false);
    });

    it("pptoken amount", async () => {
        const balance = await ppToken.balanceOf(accounts[0]);
        assert.equal(Web3Utils.fromWei(balance), "3000")
    })

    it("redeem should work", async () => {
        await boringDAO.redeem(toBytes32("BTC"), Web3Utils.toWei("2000"));
        const balance = await ppToken.balanceOf(accounts[0]);
        assert.equal(Web3Utils.fromWei(balance), "1000");
        // after redeem can't get the BOR, and exist a unlock bor
        const result = await tunnel.currentUnlock();
        console.log(Web3Utils.fromWei(result[0]));
        console.log(result[1].toNumber());
    })

});

contract("BoringDAO mint/burn", async (accounts) => {
    let boringDAO, bor, addrReso, tunnel, ppToken, addrBook, btoken, feePool;
    let [owner, trustee1, trustee2, trustee3, devUser, user, pledger2, _] = accounts;
    let keyBTC = toBytes32("BTC");
    let keybBTC = toBytes32("bBTC");
    before(async () => {
        boringDAO = await BoringDAO.deployed();
        bor = await Bor.deployed();
        addrReso = await AddressResolver.deployed();
        ppToken = await PPToken.deployed();
        tunnel = await Tunnel.deployed();
        addrBook = await AddressBook.deployed();
        btoken = await OToken.deployed();
        // oracle = await Oracle.deployed();
        feePool = await FeePool.deployed();
        // satellitePoolFactory = await StakingRewardsFactory.deployed();
    });

    it("active tunnel", async () => {
        await bor.approve(boringDAO.address, Web3Utils.toWei("3000"));
        await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("2000"));
        await tunnel.unpause();
        const con1 = await tunnel.paused();
        assert.equal(con1, true)
        await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("1000"));
        await tunnel.unpause();
        const con2 = await tunnel.paused();
        assert.equal(con2, false);
    });

    it("mint bBTC", async () => {
        await bor.approve(boringDAO.address, Web3Utils.toWei("60000"));

        let txid = "af84ace313c139b215f169c0f1ddb554ac49cf44e1e83429a3bdbdd6e387e591";
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), user, "btc address", {
            from: trustee1
        });
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), user, "btc address", {
            from: trustee2
        });
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), user, "btc address", {
            from: trustee3
        });
        const btokenBalance = await btoken.balanceOf(user);
        assert.equal(Web3Utils.fromWei(btokenBalance), "9.9792", "mint amount not correct");
        const borBalance = await bor.balanceOf(user);
        console.log("borBalance", Web3Utils.fromWei(borBalance));

    });

    it("burn bBTC", async () => {
        await bor.approve(tunnel.address, Web3Utils.toWei("100"), {
            from: user
        });
        await boringDAO.burnBToken(keyBTC, Web3Utils.toWei("0.1"), "fake btc address", {
            from: user
        });
        const balance = await btoken.balanceOf(user);
        assert.equal(Web3Utils.fromWei(balance), "9.8792", "after burned");

        const feePoolBalanceBToken = await btoken.balanceOf(feePool.address);
        const feePoolBalanceBor = await bor.balanceOf(feePool.address);
        console.log("fee pool balance btoken", Web3Utils.fromWei(feePoolBalanceBToken));
        console.log("fee pool balance bor", Web3Utils.fromWei(feePoolBalanceBor))
    });
});