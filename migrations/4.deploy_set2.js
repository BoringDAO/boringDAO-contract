const BoringDAO = artifacts.require("BoringDAO");

const Web3Utils = require('web3-utils');

const toBytes32 = key => Web3Utils.rightPad(Web3Utils.asciiToHex(key), 64)

module.exports = async (deployer) => {
    // const bd = await BoringDAO.deployed()
    // let logs = await bd.burnBToken(toBytes32("BTC"), Web3Utils.toWei("0.1"))
    // console.log(logs);
}