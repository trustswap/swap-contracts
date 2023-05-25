const { ethers, upgrades } = require("hardhat");

async function main() {
    // Deploying
    const PriceEstimator = await ethers.getContractFactory("PriceEstimator");

    const instance = await upgrades.deployProxy(PriceEstimator, ['0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02']);
    await instance.deployed();

    console.log('PROXY DEPLOYED AT', instance.address)
}

main();