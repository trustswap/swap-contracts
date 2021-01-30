// Load zos scripts and truffle wrapper function
const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;

async function deploy(options) {
  // Register v0 of SwapToken in the oz project
  add({ contractsData: [{ name: 'SwapToken', alias: 'SwapToken' }] });

  // Push implementation contracts to the network
  await push(options);

  // Create an instance of SwapToken, setting initial values
  await create(Object.assign({ contractAlias: 'SwapToken', methodName: 'initialize', methodArgs: ["TrustSwap Token","SWAP",18,100000000] }, options));
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams })
  })
}