// Load zos scripts and truffle wrapper function
const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;
const {ether} = require('@openzeppelin/test-helpers');
const {BigNumber} = require('../test/helper');

var tokenAddress = "0xCC4304A31d09258b0029eA7FE63d032f52e44EFe";
var rewardsAddress = "0x792D9470b38B32b7726d37adc3602CA3C278b5c0";
var maxStakingAmount = ether(BigNumber(50e+6)); //50 M
var unstakingPeriod = BigNumber(7); //7 Days

var rewardsAmount = ether(BigNumber(50e+6)); //50 M

const swapToken = artifacts.require("SwapToken");

async function deploy(options) {
    let token;

    // Register v0 of SwapStakingContract in the oz project
    add({ contractsData: [{ name: 'SwapStakingContract', alias: 'SwapStakingContract' }] });

    // Push implementation contracts to the network
    await push(options);

    if (!options.network.includes('mainnet')) {
        rewardsAddress = options.accounts[1];
        token = await swapToken.deployed();
        tokenAddress = swapToken.address;
    }

    console.log(`Swap Token Address: ${tokenAddress}`);
    console.log(`Rewards Address: ${rewardsAddress}`);
    console.log(`Owner Address: ${options.accounts[0]}`);

    // Create an instance of SwapStakingContract, setting initial values
    await create(Object.assign(
        { 
          contractAlias: 'SwapStakingContract', 
          methodName: 'initialize', methodArgs: [tokenAddress, rewardsAddress, maxStakingAmount.toString(), unstakingPeriod.toString()] 
        }, options));
    
    // const SwapStakingContract = artifacts.require("SwapStakingContract");
    // const stakingContract = await SwapStakingContract.deployed();

    // console.log(`Approving ${rewardsAmount.toString()} tokens for contract: '${SwapStakingContract.address}'`);
    // await token.approve(stakingContract.address, rewardsAmount, {from: rewardsAddress});
};

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams, accounts })
  })
}