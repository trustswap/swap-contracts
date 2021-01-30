// LIBRARIES
const {expect} = require('chai');
const {expectEvent, time, ether} = require('@openzeppelin/test-helpers');
const {BigNumber, getEventProperty, timeTravel} = require('./helper');

// CONTRACTS
const StakingContract = artifacts.require('SwapStakingContract');
const Token = artifacts.require('SwapToken');

// TESTING VALUES
const depositAmount1 = ether(BigNumber(1e+6)); // 1 000 000
const depositAmount2 = ether(BigNumber(2e+6)); // 2 000 000
const rewardsAmount = ether(BigNumber(1e+6)); //1 M
const maxStakingAmount = ether(BigNumber(50e+6));
const unstakingPeriod = BigNumber(7); //7 Days

const from = (account) => ({from: account});

contract('SwapStakingContract', function ([owner, rewardsAddress, account1, account2, account3, account4]) {
    describe('1. Reward is returned properly', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), 100000000);
            this.stakingContract = await StakingContract.new();
            this.stakingContract.initialize(this.token.address, rewardsAddress, maxStakingAmount.toString(), unstakingPeriod.toString());
        });

        it('1.1 should return 333333333333333333000000 reward', async function () {
            await this.token.transfer(rewardsAddress, rewardsAmount.toString());
            await this.token.transfer(account1, depositAmount1.toString());
            await this.token.transfer(account2, depositAmount2.toString());
            
            // allow staking contract
            await this.token.approve(this.stakingContract.address, maxStakingAmount.toString(), from(rewardsAddress));
            await this.token.approve(this.stakingContract.address, depositAmount1.toString(), from(account1));
            await this.token.approve(this.stakingContract.address, depositAmount2.toString(), from(account2));

            const expectedReward1 = BigNumber('333333333333333333000000');
            const expectedReward2 = BigNumber('666666666666666666000000');

            await this.stakingContract.deposit(depositAmount1.toString(), from(account1));
            await this.stakingContract.deposit(depositAmount2.toString(), from(account2));
            
            await this.stakingContract.distributeRewards();
            
            await this.stakingContract.initiateWithdrawal(from(account1));
            
            await time.increase(time.duration.days(unstakingPeriod));

            const trp = await this.stakingContract.totalRewardPoints();
            console.log(trp.toString());

            const stakeDeposit1 = await this.stakingContract.getStakeDetails(account1);
            
            expect(stakeDeposit1[0]).to.be.bignumber.equal(depositAmount1);
            expect(stakeDeposit1[3]).to.be.bignumber.equal(expectedReward1);

            console.log("Rewards for acc1:", stakeDeposit1[3].toString());

            const stakeDeposit2 = await this.stakingContract.getStakeDetails(account2);
            
            expect(stakeDeposit2[0]).to.be.bignumber.equal(depositAmount2);
            expect(stakeDeposit2[3]).to.be.bignumber.equal(expectedReward2);

            const {logs} = await this.stakingContract.executeWithdrawal(from(account1));

            const eventData1 = {
                account: account1,
                amount: depositAmount1.toString(),
                reward: expectedReward1.toString(),
            };

            expectEvent.inLogs(logs, 'WithdrawExecuted', eventData1);

            const expectedRewardPoolBalance = BigNumber('666666666666666667000000');
            expect(await this.token.balanceOf(rewardsAddress)).to.be.bignumber.equal(expectedRewardPoolBalance);
        });

        it('1.2 should return 1666666666666666666000000 reward', async function () {
            const expectedReward = BigNumber('1666666666666666666000000');

            //For account2
            await this.token.transfer(rewardsAddress, rewardsAmount.toString());
            await this.stakingContract.distributeRewards();
            
            await this.stakingContract.initiateWithdrawal(from(account2));
            
            await time.increase(time.duration.days(unstakingPeriod));
            const balance = await this.token.balanceOf(rewardsAddress);
            //console.log("Rewards Balance in 1.2 : ", BigNumber(balance).toString()); 

            const trp = await this.stakingContract.totalRewardPoints();
            //console.log(BigNumber(trp.toString()).toString());

            const stakeDeposit2 = await this.stakingContract.getStakeDetails(account2);
            expect(stakeDeposit2[0]).to.be.bignumber.equal(depositAmount2);
            expect(stakeDeposit2[3]).to.be.bignumber.equal(expectedReward);

            //console.log("Rewards for acc2:", stakeDeposit2[3].toString());
            const {logs} = await this.stakingContract.executeWithdrawal(from(account2));

            const eventData = {
                account: account2,
                amount: depositAmount2.toString(),
                reward: expectedReward.toString(),
            };

            expectEvent.inLogs(logs, 'WithdrawExecuted', eventData);

            const withdrawnRewards = await this.stakingContract.rewardsWithdrawn();
            console.log("withdrawnRewards: ", withdrawnRewards.toString());
            const distributeRewards = await this.stakingContract.rewardsDistributed();
            console.log("distributeRewards: ", distributeRewards.toString());
            //expect(await this.token.balanceOf(rewardsAddress)).to.be.bignumber.equal(BigNumber(distributeRewards.toString())-BigNumber(withdrawnRewards.toString()));
        });
    });
});
