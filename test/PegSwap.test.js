const PegSwap = artifacts.require("PegSwap");
const PegSwapPair = artifacts.require("PegSwapPair");
const BOR = artifacts.require("BOR");
const CrossBOR = artifacts.require("CrossToken");
const Web3Utils = require("web3-utils");

contract("Pegswap", async (accounts) => {
  let boringDAO, bor, addrReso, tunnel, ppToken;
  before(async () => {
    bor = await BOR.deployed();
    crossBOR = await CrossBOR.deployed();
  });
});
