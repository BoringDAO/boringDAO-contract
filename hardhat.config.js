require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("./tasks/index.js");

const { mnemonic, projectId, privateKey, mnemonicMainnet} = require("./secret.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {},
    ropsten: {
      chainId: 3,
      gasPrice: 21*10**9,
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
    mainnet: {
      url: `https://mainnet.infura.io/v3/${projectId}`,
      gasPrice: 90*10**9,
      chainId: 1,
      accounts: {
        mnemonic: mnemonicMainnet
      }
    },
    bsc_test: {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      // accounts: {
      //   mnemonic: mnemonic,
      // },
      accounts: [privateKey],
    },
    matic_test: {
      url: "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      accounts: {
        mnemonic: mnemonic
      }
    },
    matic: {
      url: "https://rpc-mainnet.maticvigil.com",
      chainId: 137,
      accounts: {
        mnemonic: mnemonicMainnet
      }
    },
    okex_test: {
      url: "https://exchaintestrpc.okex.org",
      chainId: 65,
      accounts: {
        mnemonic: mnemonic
      }
    },
    okex: {
      url: "https://exchainrpc.okex.org",
      chainId: 66
    }
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
