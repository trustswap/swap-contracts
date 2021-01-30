// Load zos scripts and truffle wrapper function
const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;

async function deploy(options) {
  // Register v0 of PriceEstimator in the oz project
  add({ contractsData: [{ name: 'PriceEstimator', alias: 'PriceEstimator' }] });

  // Push implementation contracts to the network
  await push(options);

  const UNISWAP_ROUTER_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  // Create an instance of PriceEstimator, setting initial values
  await create(Object.assign({ contractAlias: 'PriceEstimator', methodName: 'initialize', methodArgs: [UNISWAP_ROUTER_ADDRESS] }, options));
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams })
  })
}