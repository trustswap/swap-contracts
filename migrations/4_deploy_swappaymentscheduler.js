// Load zos scripts and truffle wrapper function
const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;

var tokenAddress = "";
var feeAddress = "";
var devAddress = "";

const swapToken = artifacts.require("SwapToken");

async function deploy(options) {
  if (!options.network.includes('mainnet')) {
    let token;

    // Register v0 of SwapSmartLock in the oz project
    add({ contractsData: [{ name: 'SwapSmartLock', alias: 'SwapSmartLock' }] });

    // Push implementation contracts to the network
    await push(options);

    token = await swapToken.deployed();
    tokenAddress = swapToken.address;

    feeAddress = options.accounts[1];
    devAddress = options.accounts[2];
    
    console.log(`Swap Token Address: ${tokenAddress}`);
    console.log(`Fee Wallet Address: ${feeAddress}`);
    console.log(`Dev Wallet Address: ${devAddress}`);

    // Create implementation instance of SwapSmartLock, setting initial values
    await create(Object.assign(
        { 
          contractAlias: 'SwapSmartLock', 
          methodName: 'initialize', 
          methodArgs: [tokenAddress, feeAddress, devAddress] 
        }, options));
  }
};

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams, accounts })
  })
}