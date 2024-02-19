// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import { SharesVault } from "../src/SharesVault.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestSharesVault is Test {
    address OwnerWallet;
    address user1;
    address user2;
    address user3;
    SharesVault shares;
    MockERC20 depositToken; // assets token

    function setUp() public {
        OwnerWallet = address(69);

        user1 = address(420);
        user2 = address(666);
        user3 = address(777);
        
        vm.prank(OwnerWallet);
        depositToken = new MockERC20("Deposit Token", "DT");
        depositToken.mint(user1, 10 ether);
        depositToken.mint(user2, 10 ether);
        depositToken.mint(OwnerWallet, 10 ether);
        shares = new SharesVault(address(depositToken));
        vm.stopPrank();
    }
    function setup_shareholders() public {
        vm.startPrank(user1);
        depositToken.approve(address(shares), 10 ether);
        shares.deposit(10 ether, user1);
        vm.stopPrank();
        vm.startPrank(user2);
        depositToken.approve(address(shares), 10 ether);
        shares.deposit(10 ether, user2);
        vm.stopPrank();
        assertEq(shares.balanceOf(user1), 10 ether);
        assertEq(shares.balanceOf(user2), 10 ether);
    }
    // Two functions handle the use case of a user depositing tokens and receiving shares in return.
    // deposit(uint256 assets, address receiver)
    // mint(uint256 shares, address receiver)
    function test_deposit() public {
        vm.startPrank(user1);
        depositToken.approve(address(shares), 1 ether);
        shares.deposit(1 ether, user1);
        assertEq(shares.balanceOf(user1), 1 ether);
        assertEq(depositToken.balanceOf(address(shares)), 1 ether);
        vm.stopPrank();
    }
    function test_mint() public {
        vm.startPrank(user1);
        depositToken.approve(address(shares), 1 ether);
        shares.mint(1 ether, user1);
        assertEq(shares.balanceOf(user1), 1 ether);
        assertEq(depositToken.balanceOf(address(shares)), 1 ether);
        vm.stopPrank();
    }
    // Two functions handle the redemption of shares for the underlying asset
    // withdraw(uint256 assets, address receiver)
    // redeem(uint256 shares, address receiver)
    function test_withdraw() public {
        test_mint();
        vm.startPrank(user1);
        shares.withdraw(1 ether, user1, user1);
        assertEq(shares.balanceOf(user1), 0);
        assertEq(depositToken.balanceOf(address(shares)), 0);
        assertEq(depositToken.balanceOf(user1), 10 ether);
        vm.stopPrank();
    }
    function test_redeem() public {
        test_mint();
        vm.startPrank(user1);
        shares.redeem(1 ether, user1, user1);
        assertEq(shares.balanceOf(user1), 0);
        assertEq(depositToken.balanceOf(address(shares)), 0);
        assertEq(depositToken.balanceOf(user1), 10 ether);
        vm.stopPrank();
    }
    function test_profitSharing() public {
        setup_shareholders();
        vm.startPrank(OwnerWallet);
        depositToken.approve(address(shares), 2 ether);
        shares.shareProfits(2 ether);
        vm.stopPrank();
        assertEq(depositToken.balanceOf(address(shares)), 22 ether);
        uint256 user1_value = shares.previewRedeem(10 ether);
        assertEq(user1_value, 11 ether);

    }
}

contract MockERC20 is ERC20 {
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
