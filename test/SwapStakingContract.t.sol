// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {SwapStakingContract} from "../contracts/SwapStakingContract.sol";
import {MockERC20} from "./MockERC20.sol";
// import "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/TransparentUpgradeableProxy.sol";


contract SwapStakingContractTest is Test {
 
    uint256 bscFork;

    address upgradedImplementationAddress;
    MockERC20 swap;
    MockERC20 newSwapToken;
    SwapStakingContract ltsp;  
    SwapStakingContract ltspUpgrade;        


    address user1 = address(0xdead);
    address user2 = address(0xbabe);

    address internal constant LTSP_PROXY = address(0x1714FBCFb62A4974C83EaFA0fAEC12191da6c71e);
    address internal constant LTSP_PROXY_ADMIN_MANAGER = address(0xeB8ad7b4Eaa21562009b86F66Eea2894e6890A82);
    address internal constant LTSP_PROXY_ADMIN = address(0x77e8bC029D7b8738C0d3dA6d42955f64a0C70a26);
    address internal constant SWAP_BSC = address(0x82443A77684A7Da92FdCB639c8d2Bd068a596245);
    address internal constant USER_WITH_LOCKS = address(0xc02B86B768301DE377b37572c0fB2629c99b080a);

    // create two _different_ forks during setup
    function setUp() public {
        bscFork = vm.createFork("https://bsc-dataseed.binance.org/");
        ltsp = SwapStakingContract(LTSP_PROXY);
        vm.selectFork(bscFork);
        newSwapToken = new MockERC20("NEWSWAP", "NEWSWAP", 18, UINT256_MAX);
        ltspUpgrade = new SwapStakingContract();
        upgradedImplementationAddress = address(ltspUpgrade);


        swap = MockERC20(SWAP_BSC);
    }

    function test_1() public {
        vm.startPrank(LTSP_PROXY_ADMIN);
        bytes memory upgradeCallData = "0x99a88ec40000000000000000000000001714fbcfb62a4974c83eafa0faec12191da6c71e0000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b";
        (bool success, bytes memory returnData) = address(LTSP_PROXY_ADMIN_MANAGER).call(upgradeCallData);
        console.log(success);

    }

}
