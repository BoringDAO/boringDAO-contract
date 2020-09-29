const AddressBook = artifacts.require("AddressBook");

const Web3Utils = require('web3-utils');

const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer) => {
    // const addrBook = await AddressBook.deployed()
    // await addrBook.setAssetMultiSignAddress(toBytes32("BTC"), "2MtexQG4aypNoVTQajgrYuGY4XhPm2Xr3qx");
    // await addrBook.setAddress(toBytes32("BTC"), "mrLECNfvZiwinkd2aeHJp9vc9vaaed6KzR");
    // let addr = await addrBook.asset2eth(toBytes32("BTC"), "mrLECNfvZiwinkd2aeHJp9vc9vaaed6KzR");
    // console.log(addr);
}