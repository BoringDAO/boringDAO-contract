const { networks } = require("../truffle-config");

const AddressResolver = artifacts.require("AddressResolver");
const AddressBook = artifacts.require("AddressBook");
const ParamBook = artifacts.require("ParamBook");
const Oracle = artifacts.require("Oracle");
const FeePool = artifacts.require("FeePool");
const InsurancePool = artifacts.require("InsurancePool");
const MintProposal = artifacts.require("MintProposal");
const BORToken =artifacts.require("BORToken");
const BoringDAO =artifacts.require("BoringDAO");
const Tunnel = artifacts.require("Tunnel");
const BToken = artifacts.require("BToken");
const PToken = artifacts.require("PToken");
const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");
const {trusteesAddress, btcMultiSignAddress} = require("../trustee.json");

const Web3Utils = require('web3-utils');

const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64);

module.exports = async (deployer, network, accounts) => {
    console.log("deploy account/oracle role", accounts[0]);
    console.log("trustee1", accounts[1]);
    console.log("trustee2", accounts[2]);
    console.log("trustee3", accounts[3]);
    console.log("dev user", accounts[4]);
    await deployer.deploy(AddressBook);
    const addrBook = await AddressBook.deployed();
    await deployer.deploy(AddressResolver);
    const addrResolver = await AddressResolver.deployed();

    await deployer.deploy(Oracle);
    const oracle = await Oracle.deployed();

    await deployer.deploy(ParamBook);
    const pb = await ParamBook.deployed();

    await deployer.deploy(FeePool, addrResolver.address, toBytes32("BTC"), toBytes32("bBTC"), toBytes32("P-BTC-BOR"));
    const feePool = await FeePool.deployed();

    await deployer.deploy(InsurancePool);
    const insurancePool = await InsurancePool.deployed();

    await deployer.deploy(MintProposal, addrResolver.address);
    const mintProposal = await MintProposal.deployed();

    // BOR contract
    await deployer.deploy(BORToken, "BoringDAO", "BOR", Web3Utils.toWei("200000"), addrResolver.address);
    const bor = await BORToken.deployed();

    // BoringDAO
    let trustees = [accounts[1], accounts[2], accounts[3]]
    await deployer.deploy(BoringDAO, addrResolver.address, trustees);
    const boringDAO = await BoringDAO.deployed();

    // tunnel
    await deployer.deploy(Tunnel, addrResolver.address, toBytes32("bBTC"), toBytes32("BTC"));
    const tunnel = await Tunnel.deployed();

    await deployer.deploy(BToken, "boring btc", "bBTC", toBytes32("BTC"), addrResolver.address);
    const bBTC = await BToken.deployed();

    // PToken
    await deployer.deploy(PToken, "pledge token bor", "P-BTC-BOR", addrResolver.address, toBytes32("BTC"));
    const ptoken = await PToken.deployed()

    await deployer.deploy(StakingRewardsFactory, bor.address, Math.floor(Date.now() / 1000)+3600);
    const spf = await StakingRewardsFactory.deployed();


    await addrResolver.setAddress(toBytes32("AddressBook"), addrBook.address);
    await addrResolver.setAddress(toBytes32("ParamBook"), pb.address);
    await addrResolver.setAddress(toBytes32("Oracle"), oracle.address);
    await addrResolver.setAddress(toBytes32("FeePool"), feePool.address);
    await addrResolver.setAddress(toBytes32("InsurancePool"), insurancePool.address);
    await addrResolver.setAddress(toBytes32("BoringDAO"), boringDAO.address);
    await addrResolver.setAddress(toBytes32("MintProposal"), mintProposal.address);
    await addrResolver.setAddress(toBytes32("BTC"), tunnel.address);
    await addrResolver.setAddress(toBytes32("BOR"), bor.address);
    await addrResolver.setAddress(toBytes32("bBTC"), bBTC.address);
    await addrResolver.setAddress(toBytes32("P-BTC-BOR"), ptoken.address);
    await addrResolver.setAddress(toBytes32("DevUser"), accounts[4]);
    await addrResolver.setAddress(toBytes32("BTCSatellitePoolFactory"), spf.address);

    //Address Book=> btc multisign address
    addrBook.setAssetMultiSignAddress("BTC", btcMultiSignAddress);

    // set fee rate
    const btcKey = toBytes32("BTC");
    await pb.setParams2(btcKey, toBytes32("mint fee"), Web3Utils.toWei("0.002"));
    await pb.setParams2(btcKey, toBytes32("burn fee"), Web3Utils.toWei("0.002"));
    await pb.setParams2(btcKey, toBytes32("mint fee trustee"), Web3Utils.toWei("0.15"));
    await pb.setParams2(btcKey, toBytes32("mint fee pledger"), Web3Utils.toWei("0.7"));
    await pb.setParams2(btcKey, toBytes32("mint fee dev"), Web3Utils.toWei("0.15"));
    await pb.setParams2(btcKey, toBytes32("burn fee burn"), Web3Utils.toWei("0.25"));
    await pb.setParams2(btcKey, toBytes32("burn fee insurance"), Web3Utils.toWei("0.25"));
    await pb.setParams2(btcKey, toBytes32("burn fee pledger"), Web3Utils.toWei("0.5"));
    await pb.setParams2(btcKey, toBytes32("pledge rate"), Web3Utils.toWei("0.75"));

    // BOR contract
    let mintFee = await pb.params2(btcKey, toBytes32("mint fee"))
    console.log("mint fee", Web3Utils.fromWei(mintFee));

    // oracle 
    oracle.setPrice(btcKey, Web3Utils.toWei("10000"));
    oracle.setPrice(toBytes32("BOR"), Web3Utils.toWei("150"));
    oracle.setPrice(toBytes32("YFI"), Web3Utils.toWei("30000"));
    oracle.setPrice(toBytes32("SNX"), Web3Utils.toWei("5"));
    oracle.setPrice(toBytes32("LINK"), Web3Utils.toWei("10"));
    // Pledge BOR
    await bor.approve(boringDAO.address, Web3Utils.toWei("6000"));
    await boringDAO.pledge(btcKey, Web3Utils.toWei("6000"))



}
