// LIBRARIES
const {expect} = require('chai');
const _ = require('lodash');

const {expectEvent, expectRevert, constants, time, ether} = require('@openzeppelin/test-helpers');
const {BigNumber, expectInvalidArgument, getEventProperty, timeTravel} = require('./helper');

// CONTRACTS
const SwapSmartLock = artifacts.require('SwapSmartLock');
const Token = artifacts.require('SwapToken');
const PriceEstimator = artifacts.require('PriceEstimator');

const totalSupply = ether(BigNumber(100e+6)); //100 M
const depositAmount = ether(BigNumber(1e+6)); //1 M
const feesAmount = ether(BigNumber(1000)); //1000

const from = (account) => ({from: account});

contract('SwapSmartLock', function ([owner, feesWallet, devWallet, unauthorized, account1, account2]) {
    
    describe('1. Before deployment', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());

            this.priceestimator = await PriceEstimator.new();
            this.priceestimator.initialize('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');

            this.swapSmartLock = await SwapSmartLock.new();
        });

        it('1.1. should revert when the token address is not a contract', async function () {
            const revertMessage = "[Validation] The address does not contain a contract";
            await expectRevert(this.swapSmartLock.initialize(account1, feesWallet, devWallet, this.priceestimator.address, from(owner)), revertMessage);
        });

        it('1.2. should revert when feesWallet is the zero address', async function () {
            const revertMessage = "[Validation] feesWallet is the zero address";
            await expectRevert(this.swapSmartLock.initialize(this.token.address, constants.ZERO_ADDRESS, devWallet, this.priceestimator.address, from(owner)), revertMessage);
        });

        it('1.3. should revert when devWallet is the zero address', async function () {
            const revertMessage = "[Validation] devWallet is the zero address";
            await expectRevert(this.swapSmartLock.initialize(this.token.address, devWallet, constants.ZERO_ADDRESS, this.priceestimator.address, from(owner)), revertMessage);
        });

        it('1.4. should fail when trying to deploy with wrong argument types', async function () {
            await expectInvalidArgument.address(this.swapSmartLock.initialize(this.token.address, 'not_fee_wallet_address', devWallet, this.priceestimator.address, from(owner)), 'feesWallet');
            await expectInvalidArgument.address(this.swapSmartLock.initialize(this.token.address, totalSupply, devWallet, this.priceestimator.address, from(owner)), 'feesWallet');
            await expectInvalidArgument.address(this.swapSmartLock.initialize('this.token.address', feesWallet, devWallet, this.priceestimator.address, from(owner)), 'swapTokenAddress');
            await expectInvalidArgument.address(this.swapSmartLock.initialize(0, feesWallet, devWallet, this.priceestimator.address, from(owner)), 'swapTokenAddress');
        });
    });

    describe('2. On deployment', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());

            this.priceestimator = await PriceEstimator.new();
            this.priceestimator.initialize('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');

            this.swapSmartLock = await SwapSmartLock.new();
            await this.swapSmartLock.initialize(this.token.address, feesWallet, devWallet, this.priceestimator.address, from(owner));
        });

        it('2.1. should set the token correctly', async function () {
            expect(await this.swapSmartLock.getSwapToken()).to.equal(this.token.address);
        });

        it('2.2. should set the right feesWallet', async function () {
            expect(await this.swapSmartLock.getFeesWallet()).to.equal(feesWallet);
        });

        it('2.3. should set the right devWallet', async function () {
            expect(await this.swapSmartLock.getDevWallet()).to.equal(devWallet);
        });

        it('2.4. should set the right price estimator', async function () {
            expect(await this.swapSmartLock.getPriceEstimator()).to.equal(this.priceestimator.address);
        });
    });

    describe('3. Setup', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());

            this.priceestimator = await PriceEstimator.new();
            this.priceestimator.initialize('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');

            this.swapSmartLock = await SwapSmartLock.new();
            await this.swapSmartLock.initialize(this.token.address, feesWallet, devWallet, this.priceestimator.address, from(owner));
            expect(await this.swapSmartLock.paused()).to.be.false;
        });

        it('3.1. setFeeWallet: should revert when feesWallet is the zero address', async function () {
            const revertMessage = "[Validation] feesWallet is the zero address";
            await expectRevert(
                this.swapSmartLock.setFeeWallet(constants.ZERO_ADDRESS, from(owner)), revertMessage);
        });

        it('3.2. setFeeWallet: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.setFeeWallet(
                    feesWallet,
                    from(unauthorized)
                ),
                revertMessage
            );
        });

        it('3.3. setFeeWallet: should set fee wallet address correctly', async function () {
            const newfeesWallet = account1;
            await this.swapSmartLock.setFeeWallet(newfeesWallet,from(owner));
            const actualFeeWalletAddress = await this.swapSmartLock.getFeesWallet();
            expect(newfeesWallet).to.deep.equal(actualFeeWalletAddress);
        });

        it('3.4. setDevWallet: should revert when devWallet is the zero address', async function () {
            const revertMessage = "[Validation] devWallet is the zero address";
            await expectRevert(
                this.swapSmartLock.setDevWallet(constants.ZERO_ADDRESS, from(owner)), revertMessage);
        });

        it('3.5. setDevWallet: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.setDevWallet(
                    feesWallet,
                    from(unauthorized)
                ),
                revertMessage
            );
        });

        it('3.6. setDevWallet: should set dev wallet address correctly', async function () {
            const newdevWallet = account1;
            await this.swapSmartLock.setDevWallet(newdevWallet,from(owner));
            const actualDevWalletAddress = await this.swapSmartLock.getDevWallet();
            expect(newdevWallet).to.deep.equal(actualDevWalletAddress);
        });

        it('3.7. setPriceEstimator: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.setPriceEstimator(
                    this.priceestimator.address,
                    from(unauthorized)
                ),
                revertMessage
            );
        });

        it('3.8. setPriceEstimator: should set price estimator correctly', async function () {
            await this.swapSmartLock.setPriceEstimator(this.priceestimator.address,from(owner));
            const actualPriceEstimatorAddress = await this.swapSmartLock.getPriceEstimator();
            expect(this.priceestimator.address).to.deep.equal(actualPriceEstimatorAddress);
        });

        it('3.9. setSwapToken: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.setSwapToken(
                    this.token.address,
                    from(unauthorized)
                ),
                revertMessage
            );
        });

        it('3.10. setSwapToken: should set price estimator correctly', async function () {
            await this.swapSmartLock.setSwapToken(this.token.address,from(owner));
            const actualSwapTokenAddress = await this.swapSmartLock.getSwapToken();
            expect(this.token.address).to.deep.equal(actualSwapTokenAddress);
        });

        it('3.11. pause: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.pause(
                    from(unauthorized)
                ),
                revertMessage
            );
        });

        it('3.12. unpause: should revert if not called by the contract owner', async function () {
            const revertMessage = "Ownable: caller is not the owner";
            await expectRevert(
                this.swapSmartLock.unpause(
                    from(unauthorized)
                ),
                revertMessage
            );
        });
    });

    describe('4. Schedule Payment in ETH', async function () {
        before(async function () {
            this.token = await Token.new();
            this.token.initialize('TrustSwap Token', 'SWAP', BigNumber(18), totalSupply.toString());

            this.priceestimator = await PriceEstimator.new();
            this.priceestimator.initialize('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');

            this.swapSmartLock = await SwapSmartLock.new();
            await this.swapSmartLock.initialize(this.token.address, feesWallet, devWallet, this.priceestimator.address);
        });

        it('4.1. schedulePayment: should throw if called with wrong argument types', async function () {

            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(1));

            expectInvalidArgument.address(this.swapSmartLock.schedulePayment(
                'this.token.address',
                amount.toString(), 
                1595689000,
                account2, 
                fee.toString(), 
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),'tokenAddress');

            expectInvalidArgument.uint256(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                'none', 
                1595689000,
                account2, 
                fee.toString(), 
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),'amount');

            expectInvalidArgument.uint256(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                amount.toString(), 
                'none',
                account2, 
                fee.toString(), 
                false,
                false,
                {
                    from: account1,
                    value: value 
                }),'releaseTime');

            expectInvalidArgument.address(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(), 
                1595689000,
                'not_an_address', 
                fee.toString(), 
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),'beneficiary');

            expectInvalidArgument.uint256(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                amount.toString(), 
                1595689000,
                account2, 
                'none', 
                false,
                false,
                {
                    from: account1,
                    value: value 
                }),'fee');
        });

        it('4.2. schedulePayment: should revert if called with zero amount', async function () {

            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(0));
            const fee = ether(BigNumber(1));

            const revertMessage = "[Validation] The amount has to be larger than 0";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),revertMessage);
        });

        it('4.3. schedulePayment: should revert if called with zero fee', async function () {

            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(0));

            const revertMessage = "[Validation] The fee has to be larger than 0";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),revertMessage);
        });

        it('4.4. schedulePayment: should revert if called with zero beneficiary address', async function () {

            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(1));

            const revertMessage = "[Validation] Invalid beneficiary address";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                constants.ZERO_ADDRESS,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),revertMessage);
        });

        it('4.5. schedulePayment: should revert when contract is paused', async function () {
            const revertMessage = "Pausable: paused";
            await this.swapSmartLock.pause();

            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(1));
            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                constants.ZERO_ADDRESS,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }),revertMessage);
            await this.swapSmartLock.unpause();
        });

        it('4.6. schedulePayment: Payment and Fees both are in ETH', async function () {
            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(1));

            const eventData = {
                token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                sender: account1,
                beneficiary: account2,
                id: '1',
                amount: amount,
                releaseTime: '1595689000',
                fee: fee,
                isFeeInSwap: false,
                calcFeeUsingTotalSupply: false
            };
            
            const {logs} = await this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                });
            
            expectEvent.inLogs(logs, 'PaymentScheduled', eventData);
        });

        it('4.7. schedulePayment: should revert when fee is 0', async function () {
            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(9));
            const fee = ether(BigNumber(0));

            const revertMessage = "[Validation] The fee has to be larger than 0";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }), revertMessage);
        });

        it('4.8. schedulePayment: should revert when amount is 0', async function () {
            const value = ether(BigNumber(10));
            const amount = ether(BigNumber(0));
            const fee = ether(BigNumber(1));

            const revertMessage = "[Validation] The amount has to be larger than 0";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }), revertMessage);
        });

        it('4.9. schedulePayment: should revert when fee is below required fee', async function () {
            const value = ether(BigNumber(3));
            const amount = ether(BigNumber(2));
            const fee = 10000000000000000;

            const revertMessage = "[Validation] Fee (ETH) is below minimum required fee";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }), revertMessage);
        });

        it('4.10. schedulePayment: should revert when value doesnt contain enough ETH', async function () {
            const value = ether(BigNumber(2));
            const amount = ether(BigNumber(2));
            const fee = 20000000000000000;

            const revertMessage = "[Validation] Enough ETH not sent";

            await expectRevert(this.swapSmartLock.schedulePayment(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                amount.toString(),
                1595689000,
                account2,
                fee.toString(),
                false,
                false,
                {
                   from: account1,
                   value: value 
                }), revertMessage);
        });
    });
});
