require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("./tasks/index.js");

const { mnemonic, projectId, privateKey } = require("./secret.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.6.12",
  networks: {
    hardhat: {},
    ropsten: {
      url: `https://ropsten.infura.io/v3/${projectId}`,
      accounts: {
        mnemonic: mnemonic,
      },
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${projectId}`,
      accounts: {
        mnemonic: mnemonic,
      },
    },
    bsc_test: {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      // accounts: {
      //   mnemonic: mnemonic,
      // },
      accounts: [privateKey],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    account1: {
      default: 1,
    },
    account2: {
      default: 2,
    },
  },
};
