require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("@typechain/hardhat");

const {
  BASE_GOERLI_URL,
  BASE_GOERLI_DEPLOY_KEY,
  ROLLUX_TESTNET_URL,
  ROLLUX_TESTNET_DEPLOY_KEY,
} = require("./env.json");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10,
      },
    },
  },

  networks: {
    localhost: {
      timeout: 120000,
    },
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    basegoerli: {
      url: BASE_GOERLI_URL,
      gasPrice: 30000000000,
      chainId: 84531,
      accounts: [BASE_GOERLI_DEPLOY_KEY],
    },
    rolluxtest: {
      url: ROLLUX_TESTNET_URL,
      gasPrice: 30000000000,
      chainId: 57000,
      accounts: [ROLLUX_TESTNET_DEPLOY_KEY],
    },
  },

};
