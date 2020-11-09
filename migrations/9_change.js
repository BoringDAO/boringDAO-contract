const AddressBook = artifacts.require("AddressBook");

const Web3Utils = require("web3-utils");
const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64);

module.exports = async (deployer, network, accounts) => {
    if (network == "ropsten" || network == "kovan") {
        let addressBook = await AddressBook.deployed();
        await addressBook.setAssetMultiSignAddress("BTC", "33EuGvdbEjdVzrbZYHjMkNetP3HKGd4UrS")
    }

}