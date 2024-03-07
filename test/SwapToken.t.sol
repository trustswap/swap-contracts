// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Test, console2, console} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/TransparentUpgradeableProxy.sol";
import {SwapToken} from "../src/SwapToken.sol";
import {ERC20Mock} from "openzeppelin-contracts/mocks/ERC20Mock.sol";

contract SwapTokeTest is Test {
    uint256 mainnetFork;
    address swapTokenETHAddress = address(0xCC4304A31d09258b0029eA7FE63d032f52e44EFe);
    address adminProxyOwner = address(0x088a012BF6d510aa923c814eA83807f75F7061A0);
    SwapToken newSwapTokenImplementation;
    SwapToken swapToken;
    address adminRoleAddress = 0x906935f4b42e632137504C0ea00D43C6442272bf;
    address user1 = address(0xbabe);
    ERC20Mock successOnTransferToken;


    function setUp() public {
        mainnetFork = vm.createFork("https://mainnet.infura.io/v3/5b08312dd8e8476da53576398807a640");
    }

    function testUpgradeContract_totalSupply() public {
        vm.selectFork(mainnetFork);

        newSwapTokenImplementation = new SwapToken();
        swapToken = SwapToken(swapTokenETHAddress);

        uint256 totalSupplyBeforeUpgrade = swapToken.totalSupply();

        vm.startPrank(adminProxyOwner);
        TransparentUpgradeableProxy proxyAdmin = TransparentUpgradeableProxy(payable(swapTokenETHAddress));
        proxyAdmin.upgradeTo(address(newSwapTokenImplementation));
        vm.stopPrank();

        uint256 totalSupplyAfterUpgrade = swapToken.totalSupply();
        assertEq(totalSupplyAfterUpgrade, totalSupplyBeforeUpgrade);
    }

    function testUpgradeContract_tokenDetails() public {
        vm.selectFork(mainnetFork);

        newSwapTokenImplementation = new SwapToken();
        swapToken = SwapToken(swapTokenETHAddress);

        string memory nameBeforeUpgrade = swapToken.name();
        string memory symbolBeforeUpgrade = swapToken.symbol();
        string memory versionBeforeUpgrade = swapToken.version();
        bool pausedStatusBeforeUpgrade = swapToken.paused();
        address devWalletBeforeUpgrade = swapToken.getDevWallet();
        uint256 decimalsBeforeUpgrade = swapToken.decimals();

        vm.startPrank(adminProxyOwner);
        TransparentUpgradeableProxy proxyAdmin = TransparentUpgradeableProxy(payable(swapTokenETHAddress));
        proxyAdmin.upgradeTo(address(newSwapTokenImplementation));
        vm.stopPrank();

        string memory nameAfterUpgrade = swapToken.name();
        string memory symbolAfterUpgrade = swapToken.symbol();
        string memory versionAfterUpgrade = swapToken.version();
        bool pausedStatusAfterUpgrade = swapToken.paused();
        address devWalletAfterUpgrade = swapToken.getDevWallet();
        uint256 decimalsAfterUpgrade = swapToken.decimals();

        assertEq(nameAfterUpgrade, nameBeforeUpgrade);
        assertEq(symbolBeforeUpgrade, symbolAfterUpgrade);
        assertEq(versionAfterUpgrade, versionBeforeUpgrade);
        assertEq(pausedStatusAfterUpgrade, pausedStatusBeforeUpgrade);
        assertEq(devWalletBeforeUpgrade, devWalletAfterUpgrade);
        assertEq(decimalsAfterUpgrade, decimalsBeforeUpgrade);
    }

       function testUpgradeContract_tokenDetails_2() public {
        vm.selectFork(mainnetFork);

        newSwapTokenImplementation = new SwapToken();
        swapToken = SwapToken(swapTokenETHAddress);

        uint256 roleCountAdminsBeforeUpgrade = swapToken.getRoleMemberCount(swapToken.DEFAULT_ADMIN_ROLE());

        vm.startPrank(adminProxyOwner);
        TransparentUpgradeableProxy proxyAdmin = TransparentUpgradeableProxy(payable(swapTokenETHAddress));
        proxyAdmin.upgradeTo(address(newSwapTokenImplementation));
        vm.stopPrank();

        uint256 roleCountAdminsAfterUpgrade = swapToken.getRoleMemberCount(swapToken.DEFAULT_ADMIN_ROLE());

        assertEq(roleCountAdminsAfterUpgrade, roleCountAdminsBeforeUpgrade);
    }

    function testMint() public {
         vm.selectFork(mainnetFork);

        newSwapTokenImplementation = new SwapToken();
        swapToken = SwapToken(swapTokenETHAddress);

        uint256 totalSupplyBeforeUpgrade = swapToken.totalSupply();

        vm.startPrank(adminProxyOwner);
        TransparentUpgradeableProxy proxyAdmin = TransparentUpgradeableProxy(payable(swapTokenETHAddress));
        proxyAdmin.upgradeTo(address(newSwapTokenImplementation));
        vm.stopPrank();
        
        uint256 mintAmount = 1e18;
        vm.prank(adminRoleAddress);
        swapToken.mint(user1, mintAmount);

        uint256 balanceUser1 = swapToken.balanceOf(user1);
        uint256 totalSupplyAfterUpgrade = swapToken.totalSupply();
        assertEq(totalSupplyAfterUpgrade, totalSupplyBeforeUpgrade + mintAmount);
        assertEq(balanceUser1, mintAmount);
    }

    function testWithdraw_successOnTransferToken() public {
        vm.selectFork(mainnetFork);
        successOnTransferToken = new ERC20Mock("Success", "BOOL", user1, 100e18);

        newSwapTokenImplementation = new SwapToken();
        swapToken = SwapToken(swapTokenETHAddress);

        vm.startPrank(adminProxyOwner);
        TransparentUpgradeableProxy proxyAdmin = TransparentUpgradeableProxy(payable(swapTokenETHAddress));
        proxyAdmin.upgradeTo(address(newSwapTokenImplementation));
        vm.stopPrank();

        vm.startPrank(user1);
        successOnTransferToken.approve(address(swapToken), 100e18);
        successOnTransferToken.transfer(address(swapToken), 10e18);

        vm.stopPrank();

        uint256 contractBalance = successOnTransferToken.balanceOf(address(swapToken));
        assertEq(contractBalance, 10e18);

        vm.prank(adminRoleAddress);

        swapToken.withdrawTokens(address(successOnTransferToken));

        uint256 adminBalance = successOnTransferToken.balanceOf(adminRoleAddress);
        assertEq(adminBalance, 10e18);

        contractBalance = successOnTransferToken.balanceOf(address(swapToken));
        assertEq(contractBalance, 0);
        vm.stopPrank();
    }

}
