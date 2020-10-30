const {
    expect,
    assert,
    use
} = require('chai');
const BoringDAO = artifacts.require('BoringDAO')
const Bor = artifacts.require("Bor");
const PPToken = artifacts.require("PPToken");
const Tunnel = artifacts.require("Tunnel");
const AddressResolver = artifacts.require("AddressResolver");
const AddressBook = artifacts.require("AddressBook")
const BTokenSnapshot = artifacts.require("BTokenSnapshot");
const Oracle = artifacts.require("Oracle");
const FeePool = artifacts.require("FeePool");
const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");
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
    })

});

contract("BoringDAO mint/burn", async (accounts) => {
    let boringDAO, bor, addrReso, tunnel, ppToken, addrBook, btoken, feePool;
    let [owner, trustee1, trustee2, trustee3, devUser, user, pledger2, _] = accounts;
    let keyBTC = toBytes32("BTC");
    before(async () => {
        boringDAO = await BoringDAO.deployed();
        bor = await Bor.deployed();
        addrReso = await AddressResolver.deployed();
        ppToken = await PPToken.deployed();
        tunnel = await Tunnel.deployed();
        addrBook = await AddressBook.deployed();
        btoken = await BTokenSnapshot.deployed();
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
        await bor.transfer(boringDAO.address, Web3Utils.toWei("60000"));

        let assetAddr = "1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX";
        await addrBook.setAddress(keyBTC, assetAddr, {
            from: user
        });
        let btcAddr = await addrBook.eth2asset(user, keyBTC);
        assert.equal(btcAddr, assetAddr);

        let txid = "af84ace313c139b215f169c0f1ddb554ac49cf44e1e83429a3bdbdd6e387e591";
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), assetAddr, {
            from: trustee1
        });
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), assetAddr, {
            from: trustee2
        });
        await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("10"), assetAddr, {
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
        await boringDAO.burnBToken(keyBTC, Web3Utils.toWei("0.1"), {
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

// contract("BoringDAO contract", async (accounts) => {
//      let boringDAO, bor, addrReso, ptoken, tunnel, addrBook, btoken, oracle, feePool, satellitePoolFactory;
//      let [owner, trustee1, trustee2, trustee3, devUser, user, pledger2, _] = accounts;
//      const keyBTC = toBytes32("BTC");
//      const keyBOR = toBytes32("BOR");
//      before( async () => {
//         boringDAO = await BoringDAO.deployed();
//         bor = await BORToken.deployed();
//         addrReso = await AddressResolver.deployed();
//         ptoken = await PToken.deployed();
//         tunnel = await Tunnel.deployed();
//         addrBook = await AddressBook.deployed();
//         btoken = await BToken.deployed();
//         oracle = await Oracle.deployed();
//         feePool = await FeePool.deployed();
//         satellitePoolFactory = await StakingRewardsFactory.deployed();
//      });

//         it("should approve 1000 BOR to contract", async () => {
//             await bor.approve(boringDAO.address, Web3Utils.toWei("6100"));
//             const allow = await bor.allowance(owner, boringDAO.address);
//             const borBalance = await bor.balanceOf(owner);
//             console.log("borBalance", Web3Utils.fromWei(borBalance));
//             assert.equal(Web3Utils.fromWei(allow), "6100", "Approve 6100 BOR to contract")
//         });

//         it("Get BOR address from addrReso", async () => {
//             const borAddress = await addrReso.key2address(toBytes32("BOR"));
//             assert.equal(borAddress, bor.address, "get address");
//         });

//          it("Pledge BOR", async () => {
//              console.log(keyBTC);
//              console.log(keyBOR);
//              const tx = await debug(boringDAO.pledge(keyBTC, Web3Utils.toWei("6100")));
//              const ptokenBalance = await ptoken.balanceOf(owner);
//              assert.equal(Web3Utils.fromWei(ptokenBalance), "6100");
//         });

//         it("Oracle price", async () => {
//             await oracle.setPrice(keyBTC, Web3Utils.toWei("10000"));
//             const btcPrice = await oracle.getPrice(keyBTC);
//             assert.equal(Web3Utils.fromWei(btcPrice), "10000");

//             await oracle.setPrice(keyBOR, Web3Utils.toWei("150"));
//             const borPrice = await oracle.getPrice(keyBOR);
//             assert.equal(Web3Utils.fromWei(borPrice), "150");
//         });

//         it("assocated address should work", async () => {
//             let assetAddr ="1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX";
//             await addrBook.setAddress(keyBTC, assetAddr, {from: user});
//             let btcAddr = await addrBook.eth2asset(user, keyBTC);
//             assert.equal(btcAddr, assetAddr);
//         });

//         it("Mint bBTC", async ()=> {
//             let assetAddr ="1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX";
//             let txid = "af84ace313c139b215f169c0f1ddb554ac49cf44e1e83429a3bdbdd6e387e591";
//             await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("100"), assetAddr, {from: trustee1});
//             await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("100"), assetAddr, {from: trustee2});
//             await boringDAO.approveMint(keyBTC, txid, Web3Utils.toWei("100"), assetAddr, {from: trustee3});
//             const btokenBalance = await btoken.balanceOf(user);
//             assert.equal(Web3Utils.fromWei(btokenBalance), "99.8", "mint amount not correct");
//             const borBalance = await bor.balanceOf(user);
//             console.log("borBalance", Web3Utils.fromWei(borBalance));
//         });

//         it("burn bBTC", async () => {
//             await bor.approve(tunnel.address, Web3Utils.toWei("100"), {from: user});
//             await boringDAO.burnBToken(keyBTC, Web3Utils.toWei("0.1"), {from: user});
//             const balance = await btoken.balanceOf(user);
//             assert.equal(Web3Utils.fromWei(balance), "99.7", "after burned");

//             const feePoolBalanceBToken = await btoken.balanceOf(feePool.address);
//             const feePoolBalanceBor = await bor.balanceOf(feePool.address);
//             console.log("fee pool balance btoken", Web3Utils.fromWei(feePoolBalanceBToken));
//             console.log("fee pool balance bor", Web3Utils.fromWei(feePoolBalanceBor))
//         });

//     //   //   it("claim fee", async () => {
//     //   //       const preBalance = await btoken.balanceOf(accounts[0]);
//     //   //       console.log("Pre balance is ", Web3Utils.fromWei(preBalance));
//     //   //       const pendingFee = await feePool.pendingFee(accounts[0]);
//     //   //       console.log("pending fee", Web3Utils.fromWei(pendingFee));
//     //   //       assert.equal(Web3Utils.fromWei(pendingFee), "0.00052", "pending fee ")
//     //   //       await feePool.claimFee({from: accounts[0]});
//     //   //       const afterBalance = await btoken.balanceOf(accounts[0]);
//     //   //       assert.equal(Web3Utils.fromWei(afterBalance), "0.00052", "claimed fee");

//     //   //   });

//     //     // it("redeem all", async ()=> {
//     //     //     //reddem all
//     //     //     const balance = await feePool.balanceOf(owner);
//     //     //     console.log("feepool balance", Web3Utils.fromWei(balance));
//     //     //     const pendingFee = await feePool.earned(owner);
//     //     //     console.log("pendingFee bor", Web3Utils.fromWei(pendingFee[0]));
//     //     //     console.log("pendingFee btoken", Web3Utils.fromWei(pendingFee[1]));

//     //     //     const preBalance = await btoken.balanceOf(owner);
//     //     //     console.log("Pre balance is ", Web3Utils.fromWei(preBalance));


//     //     //     let redeemAmount = 50;
//     //     //      await boringDAO.redeem(keyBTC, Web3Utils.toWei(redeemAmount.toString()))
//     //     //      const redeemBOR = await bor.balanceOf(owner)
//     //     //      assert.equal(Web3Utils.fromWei(redeemBOR), (126000-redeemAmount).toString(), "after redeemed");
//     //     //      const redeemPT = await ptoken.totalSupply();
//     //     //      assert.equal(Web3Utils.fromWei(redeemPT), "50", "ptoken after reddem ");

//     //     //     const afterBalance = await btoken.balanceOf(owner);
//     //     //     console.log("after balance is ", Web3Utils.fromWei(afterBalance));

//     //     //     const afterPendingFee = await feePool.pendingFee(owner);
//     //     //     console.log("after pendingFee", Web3Utils.fromWei(afterPendingFee));

//     //     // });

//         it("FeePool", async () => {
//             // current state
//             let feePoolBalanceOwner = await feePool.balanceOf(owner);
//             let totalPToken = await ptoken.totalSupply();
//             let tunnelBOR = await bor.balanceOf(tunnel.address);
//             let ownerBOR = await bor.balanceOf(owner);
//             console.log("owner fee pool balance", Web3Utils.fromWei(feePoolBalanceOwner), "total ptoken supply", Web3Utils.fromWei(totalPToken));
//             console.log("tunnel bor amount:", Web3Utils.fromWei(tunnelBOR));
//             console.log("owner bor amount", Web3Utils.fromWei(ownerBOR));
//             // fee state
//             let feeBOR = await bor.balanceOf(feePool.address);
//             let feeBToken = await btoken.balanceOf(feePool.address);
//             console.log("total bor fee:", Web3Utils.fromWei(feeBOR), "total btoken fee:", Web3Utils.fromWei(feeBToken));
//             // owner earned fee
//             let earnedFee = await feePool.earned(owner);
//             console.log("owner earned bor:", Web3Utils.fromWei(earnedFee[0]), "owner earned btoken", Web3Utils.fromWei(earnedFee[1]))
//             // new pledger
//             await bor.transfer(pledger2, Web3Utils.toWei("3000"), {from: owner});
//             let pledger2BORAmount = await bor.balanceOf(pledger2);
//             assert.equal(Web3Utils.fromWei(pledger2BORAmount), "3000", "owner transfer to pledger2");
//             await bor.approve(boringDAO.address, Web3Utils.toWei("3000"), {from: pledger2});
//             await boringDAO.pledge(toBytes32("BTC"), Web3Utils.toWei("3000"), {from: pledger2});
//             let ptokenPledger2Amount = await ptoken.balanceOf(pledger2);
//             assert.equal(Web3Utils.fromWei(ptokenPledger2Amount), "3000", "pledger2 ptoken amount");

//             // earned pledger
//             let feePledger2 = await feePool.earned(pledger2);
//             assert.equal(Web3Utils.fromWei(feePledger2[0]), "0");
//             assert.equal(Web3Utils.fromWei(feePledger2[1]), "0");

//             // burn bbtc
//             let logInfo = await boringDAO.burnBToken(keyBTC, Web3Utils.toWei("10"), {from: user});
//             console.log(logInfo.logs)
//             let feeBORNew = await bor.balanceOf(feePool.address);
//             console.log("fee bor new", Web3Utils.fromWei(feeBORNew));
//             let feeToOwner = await feePool.earned(pledger2);
//             console.log(Web3Utils.fromWei(feeToOwner[0]), Web3Utils.fromWei(feeToOwner[1]))
//             // claim
//             await boringDAO.redeem(toBytes32("BTC"), Web3Utils.toWei("100"), {from: owner})
//             let totalPtoken = await ptoken.totalSupply();
//             assert.equal(Web3Utils.fromWei(totalPtoken), "9000");
//             await feePool.claimFee({from: pledger2})
//             feeToOwner = await feePool.earned(owner);
//             feeToPledger2 = await feePool.earned(pledger2);
//             console.log(Web3Utils.fromWei(feeToOwner[0]), Web3Utils.fromWei(feeToOwner[1]))
//             console.log(Web3Utils.fromWei(feeToPledger2[0]), Web3Utils.fromWei(feeToPledger2[1]))
//             // burn after claim
//             await boringDAO.burnBToken(keyBTC, Web3Utils.toWei("10"), {from: user});
//             feeToOwner = await feePool.earned(owner);
//             feeToPledger2 = await feePool.earned(pledger2);
//             console.log("balance", Web3Utils.fromWei(await feePool.balanceOf(owner)))
//             console.log(Web3Utils.fromWei(feeToOwner[0]), Web3Utils.fromWei(feeToOwner[1]))
//             console.log(Web3Utils.fromWei(feeToPledger2[0]), Web3Utils.fromWei(feeToPledger2[1]))

//         });


// });

// contract("BoringDAO", async (accounts) => {
//     let boringDAO, bor, addrReso, ptoken, tunnel, addrBook, btoken, oracle, feePool, satellitePoolFactory;
//      let [owner, trustee1, trustee2, trustee3, devUser, user, pledger2, _] = accounts;
//      const keyBTC = toBytes32("BTC");
//      const keyBOR = toBytes32("BOR");
//      before( async () => {
//         boringDAO = await BoringDAO.deployed();
//         bor = await BORToken.deployed();
//         addrReso = await AddressResolver.deployed();
//         ptoken = await PToken.deployed();
//         tunnel = await Tunnel.deployed();
//         addrBook = await AddressBook.deployed();
//         btoken = await BToken.deployed();
//         oracle = await Oracle.deployed();
//         feePool = await FeePool.deployed();
//         satellitePoolFactory = await StakingRewardsFactory.deployed();
//      });
// })