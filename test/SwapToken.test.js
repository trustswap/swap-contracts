const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const { expect } = require('chai');

const SwapToken = contract.fromArtifact('SwapToken');

describe('SwapToken', function () {
  const [ deployer, other ] = accounts;
  console.log("deployer: ", deployer);
  const name = 'Swap Token';
  const symbol = 'SWAPT';
  const decimals = new BN('18');
  const totalSupply = new BN('100000000000000000000000000'); //100 M
  const amount = new BN('5000');

  const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
  
  const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');

  beforeEach(async function () {
    this.token = await SwapToken.new({ from: deployer });
    this.token.initialize(name, symbol, decimals, 100000000, {from : deployer});
  });

  describe('name, symbol, decimals and total supply', function () {
    it('check name, symbol, decimals and total supply', async function () {
      expect(await this.token.name()).to.equal(name);
      expect(await this.token.symbol()).to.equal(symbol);
      expect(await this.token.decimals()).to.be.bignumber.equal(decimals);
      expect(await this.token.totalSupply()).to.be.bignumber.equal(totalSupply);
    });
  });

  describe('balance', function () {
    it('check deployer balance', async function () {
      expect(await this.token.balanceOf(deployer)).to.be.bignumber.equal(totalSupply);
    });
  });

  describe('Access roles', function () {
    it('deployer has the default admin role', async function () {
      expect(await this.token.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.bignumber.equal('1');
      expect(await this.token.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(deployer);
    });

    it('deployer has the pauser role', async function () {
      expect(await this.token.getRoleMemberCount(PAUSER_ROLE)).to.be.bignumber.equal('1');
      expect(await this.token.getRoleMember(PAUSER_ROLE, 0)).to.equal(deployer);
    });

    it('pauser role admin is the default admin', async function () {
      expect(await this.token.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
    });
  });

  describe('pausing', function () {
    it('deployer can pause', async function () {
      const receipt = await this.token.pause({ from: deployer });
      expectEvent(receipt, 'Paused', { account: deployer });

      expect(await this.token.paused()).to.equal(true);
    });

    it('deployer can unpause', async function () {
      await this.token.pause({ from: deployer });

      const receipt = await this.token.unpause({ from: deployer });
      expectEvent(receipt, 'Unpaused', { account: deployer });

      expect(await this.token.paused()).to.equal(false);
    });

    it('other accounts cannot pause', async function () {
      await expectRevert(this.token.pause({ from: other }), 'SwapToken: must have pauser role to pause');
    });
  });

  describe('transfer', function() {
    it('deployer transfer to other account', async function () {
      const receipt = await this.token.transfer(other, amount, { from: deployer });
      expectEvent(receipt, 'Transfer', { from: deployer, to: other, value: amount });

      expect(await this.token.balanceOf(other)).to.be.bignumber.equal(amount);
    });
  });
  describe('burning', function () {
    it('holders can burn their tokens', async function () {
      await this.token.transfer(other, amount, { from: deployer });

      const receipt = await this.token.burn(amount.subn(1), { from: other });
      expectEvent(receipt, 'Transfer', { from: other, to: ZERO_ADDRESS, value: amount.subn(1) });

      expect(await this.token.balanceOf(other)).to.be.bignumber.equal('1');
    });
  });
});