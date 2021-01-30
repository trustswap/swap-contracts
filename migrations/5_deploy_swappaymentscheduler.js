// Load zos scripts and truffle wrapper function
const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;

var tokenAddress = "";
var feeAddress = "";
var devAddress = "";
var priceEstimatorAddress = "";

const swapToken = artifacts.require("SwapToken");
const PriceEstimator = artifacts.require("PriceEstimator");

async function deploy(options) {
  if (!options.network.includes('mainnet')) {
    let token;
    let priceEstimator;

    // Register v0 of SwapStakingContract in the oz project
    add({ contractsData: [{ name: 'SwapSmartLock', alias: 'SwapSmartLock' }] });

    // Push implementation contracts to the network
    await push(options);

    token = await swapToken.deployed();
    tokenAddress = swapToken.address;

    priceEstimator = await PriceEstimator.deployed();
    priceEstimatorAddress = priceEstimator.address;

    //feeAddress = options.accounts[1];
    //devAddress = options.accounts[2];
    feeAddress = "0xbD8C0f92379d0c8312089Dc18D8271b113964AFF";
    devAddress = "0xa3f82591cDa028dE8fb2dea206E98E0D75f5Ab23";

    console.log(`Swap Token Address: ${tokenAddress}`);
    console.log(`Fee Wallet Address: ${feeAddress}`);
    console.log(`Dev Wallet Address: ${devAddress}`);
    console.log(`Price Estimator Address: ${priceEstimatorAddress}`);

    // Create implementation instance of SwapSmartLock, setting initial values
    await create(Object.assign(
        { 
          contractAlias: 'SwapSmartLock', 
          methodName: 'initialize', 
          methodArgs: [tokenAddress, feeAddress, devAddress, priceEstimatorAddress] 
        }, options));
  }
};

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams, accounts })
  })
}