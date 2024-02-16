// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {SwapStakingContract} from "../contracts/SwapStakingContract.sol";
import {MockERC20} from "./MockERC20.sol";
// import "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
// import {TransparentUpgradeableProxy} from "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";



contract SwapStakingContractTest is Test {
 
    uint256 bscFork;

    address upgradedImplementationAddress;
    // MockERC20 erc20;
    SwapStakingContract ltsp;  
    SwapStakingContract ltspUpgrade;        
      
    address user1 = address(0xdead);
    address user2 = address(0xbabe);

    address internal constant LTSP_PROXY = address(0x1714FBCFb62A4974C83EaFA0fAEC12191da6c71e);
    address internal constant LTSP_PROXY_ADMIN = address(0x77e8bC029D7b8738C0d3dA6d42955f64a0C70a26);
    address internal constant SWAP_BSC = address(0x82443A77684A7Da92FdCB639c8d2Bd068a596245);
    address internal constant USER_WITH_LOCKS = address(0xc02B86B768301DE377b37572c0fB2629c99b080a);

    // create two _different_ forks during setup
    function setUp() public {
        bscFork = vm.createFork("https://bsc-dataseed.binance.org/");
        ltsp = SwapStakingContract(LTSP_PROXY);
        vm.selectFork(bscFork);
        // newSwapToken = new MockERC20("NEWSWAP", "NEWSWAP", 18);
        ltspUpgrade = new SwapStakingContract();
        upgradedImplementationAddress = address(ltspUpgrade);

        // proxyAdmin = ProxyAdmin(LTSP_PROXY_ADMIN);

        // swap = MockERC20(SWAP_BSC);
    }



}
