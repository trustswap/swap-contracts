// LIBRARIES
const {expect} = require('chai');
const _ = require('lodash');

const {expectEvent, expectRevert, constants, time, ether} = require('@openzeppelin/test-helpers');
const {BigNumber, expectInvalidArgument, getEventProperty, timeTravel} = require('./helper');

// CONTRACTS
const StakingContract = artifacts.require('SwapStakingContract');
const Token = artifacts.require('SwapToken');

const totalSupply = ether(BigNumber(100e+6)); //100 M
const depositAmount = ether(BigNumber(1e+6)); //1 M
const rewardsAmount = ether(BigNumber(10e+6)); //10 M
const maxStakingAmount = ether(BigNumber(50e+6));
const unstakingPeriod = BigNumber(7); //7 Days

const from = (account) => ({from: account});

const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');
const OWNER_ROLE = web3.utils.soliditySha3('OWNER_ROLE');
const REWARDS_DISTRIBUTOR_ROLE = web3.utils.soliditySha3('REWARDS_DISTRIBUTOR_ROLE');

contract('SwapStakingContract', function ([owner, rewardsAddress, unauthorized, account1, account2, account3]) {
    
    describe('1. Before deployment', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());
            this.stakingContract = await StakingContract.new();
        });

        it('1.1. should fail when trying to deploy with wrong argument types', async function () {
            await expectInvalidArgument.address(this.stakingContract.initialize(this.token.address, 'not_rewards_address', maxStakingAmount, unstakingPeriod), '_rewardsAddress');
            await expectInvalidArgument.address(this.stakingContract.initialize(this.token.address, rewardsAmount, maxStakingAmount, unstakingPeriod), '_rewardsAddress');
            await expectInvalidArgument.address(this.stakingContract.initialize('this.token.address', rewardsAddress, maxStakingAmount, unstakingPeriod), '_token');
            await expectInvalidArgument.address(this.stakingContract.initialize(0, rewardsAddress, maxStakingAmount, unstakingPeriod), '_token');
        });

        it('1.2. should revert when the token address is not a contract', async function () {
            const revertMessage = "[Validation] The address does not contain a contract";
            await expectRevert(this.stakingContract.initialize(account1, rewardsAddress, maxStakingAmount, unstakingPeriod), revertMessage);
        });

        it('1.3. should revert when _rewardsAddress is the zero address', async function () {
            const revertMessage = "[Validation] _rewardsAddress is the zero address";
            await expectRevert(this.stakingContract.initialize(this.token.address, constants.ZERO_ADDRESS, maxStakingAmount, unstakingPeriod), revertMessage);
        });
    });

    describe('2. On deployment', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());
            this.stakingContract = await StakingContract.new();
            this.stakingContract.initialize(this.token.address, rewardsAddress, maxStakingAmount, unstakingPeriod);
            this.deployTimestamp = await time.latest();
        });

        it('2.1. should set the token correctly', async function () {
            expect(await this.stakingContract.token()).to.equal(this.token.address);
        });

        it('2.2. should set the right rewardsAddress', async function () {
            expect(await this.stakingContract.rewardsAddress()).to.equal(rewardsAddress);
        });

        it('2.3. should set the current status to unpaused', async function () {
            expect(await this.stakingContract.paused()).to.be.false;
        });

        it('2.4 deployer has the default admin role', async function () {
            expect(await this.stakingContract.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.bignumber.equal('1');
            expect(await this.stakingContract.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner);
        });
      
        it('2.5 deployer has the pauser role', async function () {
            expect(await this.stakingContract.getRoleMemberCount(PAUSER_ROLE)).to.be.bignumber.equal('1');
            expect(await this.stakingContract.getRoleMember(PAUSER_ROLE, 0)).to.equal(owner);
        });
      
        it('2.6 pauser role admin is the default admin', async function () {
            expect(await this.token.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
        });

        it('2.7 deployer has the rewards distribution role', async function () {
            expect(await this.stakingContract.getRoleMemberCount(REWARDS_DISTRIBUTOR_ROLE)).to.be.bignumber.equal('1');
            expect(await this.stakingContract.getRoleMember(REWARDS_DISTRIBUTOR_ROLE, 0)).to.equal(owner);
        });

        it('2.8 deployer has the owner role', async function () {
            expect(await this.stakingContract.getRoleMemberCount(OWNER_ROLE)).to.be.bignumber.equal('1');
            expect(await this.stakingContract.getRoleMember(OWNER_ROLE, 0)).to.equal(owner);
        });
    });

    describe('3. Setup', async function () {
        before(async function () {
            this.token = await Token.new('TrustSwap Token', 'SWAP', BigNumber(18));
            this.stakingContract = await StakingContract.new(this.token.address, rewardsAddress);
            this.stakingContract.initialize(this.token.address, rewardsAddress, maxStakingAmount, unstakingPeriod);
            expect(await this.stakingContract.paused()).to.be.false;
        });

        it('3.1. setRewardAddress: should revert when _rewardsAddress is the zero address', async function () {
            const revertMessage = "[Validation] _rewardsAddress is the zero address";
            await this.stakingContract.pause(from(owner));
            await expectRevert(
                this.stakingContract.setRewardAddress(constants.ZERO_ADDRESS, from(owner)), revertMessage);
            await this.stakingContract.unpause(from(owner));
        });

        it('3.2. setRewardAddress: should revert if not called by the contract owner', async function () {
            const revertMessage = "[Validation] The caller must have owner role to set rewards address";
            await this.stakingContract.pause(from(owner));
            await expectRevert(
                this.stakingContract.setRewardAddress(
                    rewardsAddress,
                    from(unauthorized)
                ),
                revertMessage
            );
            await this.stakingContract.unpause(from(owner));
        });

        it('3.3. setRewardAddress: should revert when contract is not paused', async function () {
            const revertMessage = "Pausable: not paused";
            await expectRevert(
                this.stakingContract.setRewardAddress(
                    rewardsAddress,
                    from(owner)
                ),
                revertMessage
            );
        });

        it('3.4. setRewardAddress: should revert if set same reward address', async function () {
            const revertMessage = "[Validation] _rewardsAddress is already set to given address";
            await this.stakingContract.pause();
            await expectRevert(
                this.stakingContract.setRewardAddress(
                    rewardsAddress,
                    from(owner)
                ),
                revertMessage
            );
            await this.stakingContract.unpause();
        });

        it('3.6. setRewardAddress: should set reward address correctly', async function () {
            const newRewardsAddress = account1;
            await this.stakingContract.pause();
            await this.stakingContract.setRewardAddress(newRewardsAddress,from(owner));
            await this.stakingContract.unpause();
            const actualRewardAddress = await this.stakingContract.rewardsAddress();
            expect(newRewardsAddress).to.deep.equal(actualRewardAddress);
        });
    });

    describe('4. Deposit and withdraw', async function () {
        before(async function () {
            this.token = await Token.new('TrustSwap Token', 'SWAP', BigNumber(18));
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());
            this.stakingContract = await StakingContract.new();
            this.stakingContract.initialize(this.token.address, rewardsAddress, maxStakingAmount.toString(), unstakingPeriod.toString());
            await this.token.transfer(rewardsAddress, rewardsAmount);
            await this.token.transfer(account1, depositAmount);
            await this.token.approve(this.stakingContract.address, rewardsAmount, from(rewardsAddress));
            await this.token.approve(this.stakingContract.address, depositAmount, from(account1));
        });

        it('4.1. deposit: should throw if called with wrong argument types', async function () {
            await expectInvalidArgument.uint256(this.stakingContract.deposit('none'), 'amount');
        });

        it('4.2. deposit: should revert when contract is paused', async function () {
            const revertMessage = 'Pausable: paused';
            await this.stakingContract.pause();
            await expectRevert(this.stakingContract.deposit(depositAmount), revertMessage);
            await this.stakingContract.unpause();
        });

        it('4.3. deposit: should revert if deposit is called with an amount of 0', async function () {
            const message = "[Validation] The stake deposit has to be larger than 0";
            await expectRevert(this.stakingContract.deposit('0'), message);
        });

        it('4.4. deposit: should revert if the account already has a stake deposit', async function () {
            const message = "[Deposit] You already have a stake";
            await this.stakingContract.deposit(depositAmount, from(account1));
            await expectRevert(this.stakingContract.deposit(depositAmount, from(account1)), message);
        });

        it('4.5. deposit: should revert if the transfer fails because of insufficient funds', async function () {
            const exceedsBalanceMessage = "ERC20: transfer amount exceeds balance.";
            await expectRevert(this.stakingContract.deposit(depositAmount, from(account2)), exceedsBalanceMessage);
            await this.token.transfer(account2, depositAmount);
            const exceedsAllowanceMessage = "ERC20: transfer amount exceeds allowance.";
            await expectRevert(this.stakingContract.deposit(depositAmount, from(account2)), exceedsAllowanceMessage);
        });

        it('4.7. deposit: should create a new deposit for the depositing account and emit StakeDeposited(msg.sender, amount)', async function () {
            const eventData = {
                account: account2,
                amount: depositAmount
            };

            const initialBalance = await this.token.balanceOf(this.stakingContract.address);
            await this.token.approve(this.stakingContract.address, depositAmount, from(account2));
            const {logs} = await this.stakingContract.deposit(depositAmount, from(account2));
            const currentBalance = await this.token.balanceOf(this.stakingContract.address);

            expectEvent.inLogs(logs, 'StakeDeposited', eventData);
            expect(initialBalance.add(depositAmount)).to.be.bignumber.equal(currentBalance);
        });

        it('4.8. deposit: should have current total stake less than current maximum staking limit', async function () {
            const totalStake = await this.stakingContract.currentTotalStake();
            const currentMaxLimit = await this.stakingContract.maxStakingAmount();

            expect(totalStake).to.be.bignumber.below(currentMaxLimit);
            expect(currentMaxLimit).to.be.bignumber.equal(maxStakingAmount);
        });

        it('4.9. deposit: should revert if trying to deposit more than staking limit', async function () {
            const revertMessage = "[Deposit] Your deposit would exceed the current staking limit";
            await this.token.transfer(account3, maxStakingAmount);
            await this.token.approve(account3, maxStakingAmount, from(account3));

            await expectRevert(this.stakingContract.deposit(maxStakingAmount, from(account3)), revertMessage);
        });

        it('4.10. initiateWithdrawal: should revert when contract is paused', async function () {
            await this.stakingContract.pause();
            await expectRevert(this.stakingContract.initiateWithdrawal(from(account1)), "Pausable: paused");
            await this.stakingContract.unpause();
        });

        it('4.11. initiateWithdrawal: should revert if the account has no stake deposit', async function () {
            const revertMessage = "[Initiate Withdrawal] There is no stake deposit for this account";
            await expectRevert(this.stakingContract.initiateWithdrawal(from(unauthorized)), revertMessage)
        });

        it('4.12. initiateWithdrawal: should emit the WithdrawInitiated(msg.sender, stakeDeposit.amount) event', async function () {
            const eventData = {
                account: account1,
                amount: depositAmount,
            };
            
            await this.token.transfer(rewardsAddress, rewardsAmount);
            await this.stakingContract.distributeRewards();
            
            const {logs} = await this.stakingContract.initiateWithdrawal(from(account1));
            expectEvent.inLogs(logs, 'WithdrawInitiated', eventData);
        });

        it('4.13. initiateWithdrawal: should revert if account has already initiated the withdrawal', async function () {
            const revertMessage = "[Initiate Withdrawal] You already initiated the withdrawal";
            await expectRevert(this.stakingContract.initiateWithdrawal(from(account1)), revertMessage)
        });

        it('4.14. executeWithdrawal: should revert when contract is paused', async function () {
            const revertMessage = "Pausable: paused";
            await this.stakingContract.pause();
            await expectRevert(this.stakingContract.executeWithdrawal(from(account1)), revertMessage);
            await this.stakingContract.unpause();
        });

        it('4.15. executeWithdrawal: should revert if there is no deposit on the account', async function () {
            const revertMessage = "[Withdraw] There is no stake deposit for this account";
            await expectRevert(this.stakingContract.executeWithdrawal(), revertMessage);
        });

        it('4.16. executeWithdrawal: should revert if the withdraw was not initialized', async function () {
            const revertMessage = "[Withdraw] Withdraw is not initialized";
            await expectRevert(this.stakingContract.executeWithdrawal(from(account2)), revertMessage);
        });

        it('4.17. executeWithdrawal: should revert if unstaking period did not pass', async function () {
            const revertMessage = '[Withdraw] The unstaking period did not pass';
            await expectRevert(this.stakingContract.executeWithdrawal(from(account1)), revertMessage);
        });

        it('4.18. executeWithdrawal: should revert if transfer fails on reward', async function () {
            const revertMessage = "ERC20: transfer amount exceeds allowance";

            await time.increase(time.duration.days(unstakingPeriod));

            await this.token.decreaseAllowance(
                this.stakingContract.address,
                rewardsAmount,
                from(rewardsAddress)
            );

            await expectRevert(this.stakingContract.executeWithdrawal(from(account1)), revertMessage);
        });

        it('4.19. getStakeDetails: should return the stake deposit and current reward for a specified account', async function () {
            const stakeDeposit = await this.stakingContract.getStakeDetails(account1);

            expect(stakeDeposit[0]).to.be.bignumber.equal(depositAmount);
            expect(stakeDeposit[3]).to.be.bignumber.above(BigNumber(0));
        });

        it('4.20. executeWithdrawal: should transfer the initial staking deposit and the correct reward and emit WithdrawExecuted', async function () {
            await this.token.increaseAllowance(
                this.stakingContract.address,
                rewardsAmount,
                from(rewardsAddress)
            );
            
            const {logs} = await this.stakingContract.executeWithdrawal(from(account1));

            const eventData = {
                account: account1,
                amount: depositAmount,
            };

            expectEvent.inLogs(logs, 'WithdrawExecuted', eventData);
        });
    });
});
