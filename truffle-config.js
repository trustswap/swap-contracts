const HDWalletProvider = require("@truffle/hdwallet-provider");
const { toWei } = require('web3-utils');

require('dotenv').config()  // Store environment-specific variable from '.env' to process.env

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      provider: () => new HDWalletProvider(process.env.PK, "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY),
      port: 8545,
      network_id: "4",
      gas: 7000000,
      gasPrice: 40000000000
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
    ropsten: {
      provider: () => new HDWalletProvider(process.env.PK, "https://ropsten.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 3,       // Ropsten's id
      gas: 8000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: toWei('54', 'gwei'),
      confirmations: 0,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 300,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    mainnet_fork: {
      host: "localhost",
      port: 8545,
      gas: 6000000,
      gasPrice: 54000000000,
      network_id: "*",
      skipDryRun: true
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
       version: "0.6.2",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
       settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
      //  evmVersion: "byzantium"
      }
    }
  }
}
