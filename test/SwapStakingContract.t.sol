// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {SwapStakingContract} from "../src/SwapStakingContract.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/TransparentUpgradeableProxy.sol";

import "forge-std/console.sol";

contract SwapStakingContractTest is Test {
 
    uint256 bscFork;

    address upgradedImplementationAddress;
    ERC20Mock swap;
    ERC20Mock newSwapToken;
    SwapStakingContract ltsp;  
    SwapStakingContract ltspUpgrade;        


    address user1 = address(0xdead);
    address user2 = address(0xbabe);

    address internal constant LTSP_PROXY = address(0x1714FBCFb62A4974C83EaFA0fAEC12191da6c71e);
    address internal constant LTSP_PROXY_ADMIN_MANAGER = address(0xeB8ad7b4Eaa21562009b86F66Eea2894e6890A82);
    address internal constant LTSP_PROXY_ADMIN = address(0x77e8bC029D7b8738C0d3dA6d42955f64a0C70a26);
    address internal constant SWAP_BSC = address(0x82443A77684A7Da92FdCB639c8d2Bd068a596245);
    address internal constant USER_WITH_LOCKS = address(0xc02B86B768301DE377b37572c0fB2629c99b080a);

    ProxyAdmin proxyManager = ProxyAdmin(payable(0xeB8ad7b4Eaa21562009b86F66Eea2894e6890A82));
    TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(LTSP_PROXY));

    // create two _different_ forks during setup
    function setUp() public {
        bscFork = vm.createFork("https://bsc-dataseed.binance.org/");
        ltsp = SwapStakingContract(LTSP_PROXY);
        vm.selectFork(bscFork);
        newSwapToken = new ERC20Mock("NEWSWAP", "NEWSWAP", LTSP_PROXY_ADMIN, UINT256_MAX / 2);
        ltspUpgrade = new SwapStakingContract();
        upgradedImplementationAddress = address(ltspUpgrade);
        address result = proxyManager.getProxyImplementation(proxy);
        console.log("result", result);


        swap = ERC20Mock(SWAP_BSC);
    }

    function test_migrateWorks() public {
        vm.selectFork(bscFork);

        vm.startPrank(LTSP_PROXY_ADMIN);
        proxyManager.upgrade(proxy, upgradedImplementationAddress);
        uint256 oldBalance = swap.balanceOf(LTSP_PROXY);
        newSwapToken.approve(LTSP_PROXY, UINT256_MAX);
        ltsp.migrateSwap(address(newSwapToken), LTSP_PROXY_ADMIN);
        uint256 newBalance = newSwapToken.balanceOf(LTSP_PROXY);
        assertEq(oldBalance, newBalance);

    }

}
