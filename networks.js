const HDWalletProvider = require("@truffle/hdwallet-provider");
const { toWei } = require('web3-utils');

require('dotenv').config()  // Store environment-specific variable from '.env' to process.env

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    ropsten: {
      provider: () => new HDWalletProvider(process.env.PK, "https://ropsten.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 3,       // Ropsten's id
      gas: 8000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: toWei('54', 'gwei'),
      confirmations: 0,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 300,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    mainnet: {
      provider: () => new HDWalletProvider(process.env.PK, "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY),
      port: 8545,
      network_id: "1",
      gas: 6000000,
      gasPrice: 54000000000,
      confirmations: 2,
      skipDryRun: true
    },
    mainnet_fork: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 6000000,
      gasPrice: 54000000000,
      networkId: '*',
      skipDryRun: true
    }
  },
};
