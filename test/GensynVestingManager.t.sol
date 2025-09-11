// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/GensynToken.sol";
import "../src/GensynVestingManager.sol";
import "../src/GensynVestingWallet.sol";

contract GensynVestingManagerTest is Test {
    GensynToken public token;
    GensynVestingManager public vestingManager;
    address public owner;
    address public beneficiary1;
    address public beneficiary2;
    
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public constant VESTING_AMOUNT = 1_000_000 * 10**18;
    
    event VestingWalletCreated(
        address indexed beneficiary, 
        address indexed vestingWallet, 
        uint256 amount, 
        uint256 startTime
    );
    event TokensAllocated(address indexed beneficiary, uint256 amount);
    
    function setUp() public {
        owner = makeAddr("owner");
        beneficiary1 = makeAddr("beneficiary1");
        beneficiary2 = makeAddr("beneficiary2");
        
        vm.startPrank(owner);
        token = new GensynToken(owner);
        vestingManager = new GensynVestingManager(address(token), owner);
        
        // Approve vesting manager to spend tokens
        token.approve(address(vestingManager), TOTAL_SUPPLY);
        vm.stopPrank();
    }
    
    function testInitialState() public {
        assertEq(address(vestingManager.gensynToken()), address(token));
        assertEq(vestingManager.owner(), owner);
        assertEq(vestingManager.CLIFF_DURATION(), 365 days);
        assertEq(vestingManager.VESTING_DURATION(), 3 * 365 days);
        assertEq(vestingManager.VESTING_PERIOD(), 30 days);
    }
    
    function testCreateVestingWallet() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokensAllocated(beneficiary1, VESTING_AMOUNT);
        address vestingWallet = vestingManager.createVestingWallet(
            beneficiary1,
            VESTING_AMOUNT,
            startTime
        );
        
        assertTrue(vestingWallet != address(0));
        assertEq(token.balanceOf(vestingWallet), VESTING_AMOUNT);
        assertEq(vestingManager.totalAllocated(beneficiary1), VESTING_AMOUNT);
        
        address[] memory wallets = vestingManager.getVestingWallets(beneficiary1);
        assertEq(wallets.length, 1);
        assertEq(wallets[0], vestingWallet);
    }
    
    function testCreateVestingWalletWithCurrentTime() public {
        vm.prank(owner);
        address vestingWallet = vestingManager.createVestingWallet(
            beneficiary1,
            VESTING_AMOUNT,
            0 // Should use current time
        );
        
        GensynVestingWallet wallet = GensynVestingWallet(payable(vestingWallet));
        assertEq(wallet.start(), block.timestamp);
    }
    
    function testCreateMultipleVestingWallets() public {
        address[] memory beneficiaries = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory startTimes = new uint256[](2);
        
        beneficiaries[0] = beneficiary1;
        beneficiaries[1] = beneficiary2;
        amounts[0] = VESTING_AMOUNT;
        amounts[1] = VESTING_AMOUNT / 2;
        startTimes[0] = block.timestamp;
        startTimes[1] = block.timestamp + 1 days;
        
        vm.prank(owner);
        vestingManager.createMultipleVestingWallets(beneficiaries, amounts, startTimes);
        
        assertEq(vestingManager.totalAllocated(beneficiary1), VESTING_AMOUNT);
        assertEq(vestingManager.totalAllocated(beneficiary2), VESTING_AMOUNT / 2);
        
        address[] memory wallets1 = vestingManager.getVestingWallets(beneficiary1);
        address[] memory wallets2 = vestingManager.getVestingWallets(beneficiary2);
        
        assertEq(wallets1.length, 1);
        assertEq(wallets2.length, 1);
    }
    
    function testVestingSchedule() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        address vestingWallet = vestingManager.createVestingWallet(
            beneficiary1,
            VESTING_AMOUNT,
            startTime
        );
        
        GensynVestingWallet wallet = GensynVestingWallet(payable(vestingWallet));
        
        // Check initial state
        assertEq(wallet.releasable(address(token)), 0);
        
        // Fast forward to 6 months (before cliff)
        vm.warp(startTime + 180 days);
        assertEq(wallet.releasable(address(token)), 0);
        
        // Fast forward to 1 year (after cliff)
        vm.warp(startTime + 365 days);
        uint256 expectedVested = VESTING_AMOUNT / 3; // 1/3 of total after 1 year
        assertApproxEqAbs(wallet.releasable(address(token)), expectedVested, 1e15); // Allow small rounding error
        
        // Fast forward to 2 years
        vm.warp(startTime + 2 * 365 days);
        expectedVested = (VESTING_AMOUNT * 2) / 3; // 2/3 of total after 2 years
        assertApproxEqAbs(wallet.releasable(address(token)), expectedVested, 1e15);
        
        // Fast forward to 3 years (fully vested)
        vm.warp(startTime + 3 * 365 days);
        assertEq(wallet.releasable(address(token)), VESTING_AMOUNT);
    }
    
    function testReleaseVestedTokens() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        address vestingWallet = vestingManager.createVestingWallet(
            beneficiary1,
            VESTING_AMOUNT,
            startTime
        );
        
        // Fast forward to after cliff
        vm.warp(startTime + 365 days);
        
        GensynVestingWallet wallet = GensynVestingWallet(payable(vestingWallet));
        uint256 releasableAmount = wallet.releasable(address(token));
        
        // Release tokens
        vm.prank(beneficiary1);
        wallet.release(address(token));
        
        assertEq(token.balanceOf(beneficiary1), releasableAmount);
        assertEq(wallet.released(address(token)), releasableAmount);
    }
    
    function testReleaseAll() public {
        uint256 startTime = block.timestamp;
        
        // Create two vesting wallets for the same beneficiary
        vm.startPrank(owner);
        vestingManager.createVestingWallet(beneficiary1, VESTING_AMOUNT, startTime);
        vestingManager.createVestingWallet(beneficiary1, VESTING_AMOUNT / 2, startTime);
        vm.stopPrank();
        
        // Fast forward to after cliff
        vm.warp(startTime + 365 days);
        
        uint256 totalVested = vestingManager.getTotalVestedAmount(beneficiary1);
        
        // Release all vested tokens
        uint256 totalReleased = vestingManager.releaseAll(beneficiary1);
        
        assertEq(totalReleased, totalVested);
        assertEq(token.balanceOf(beneficiary1), totalVested);
    }
    
    function testGetVestingInfo() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        address vestingWallet = vestingManager.createVestingWallet(
            beneficiary1,
            VESTING_AMOUNT,
            startTime
        );
        
        (
            address beneficiary,
            uint256 start,
            uint256 cliff,
            uint256 duration,
            uint256 released,
            uint256 releasable
        ) = vestingManager.getVestingInfo(vestingWallet);
        
        assertEq(beneficiary, beneficiary1);
        assertEq(start, startTime);
        assertEq(cliff, 365 days + startTime); // cliff is absolute timestamp
        assertEq(duration, 3 * 365 days);
        assertEq(released, 0);
        assertEq(releasable, 0);
    }
    
    function testOnlyOwnerCanCreateVesting() public {
        vm.prank(beneficiary1);
        vm.expectRevert();
        vestingManager.createVestingWallet(beneficiary1, VESTING_AMOUNT, block.timestamp);
    }
    
    function testCannotCreateVestingWithInvalidParams() public {
        vm.startPrank(owner);
        
        // Zero address beneficiary
        vm.expectRevert("GensynVestingManager: beneficiary cannot be zero address");
        vestingManager.createVestingWallet(address(0), VESTING_AMOUNT, block.timestamp);
        
        // Zero amount
        vm.expectRevert("GensynVestingManager: amount must be greater than 0");
        vestingManager.createVestingWallet(beneficiary1, 0, block.timestamp);
        
        vm.stopPrank();
    }
    
    function testArrayLengthMismatch() public {
        address[] memory beneficiaries = new address[](2);
        uint256[] memory amounts = new uint256[](1); // Different length
        uint256[] memory startTimes = new uint256[](2);
        
        beneficiaries[0] = beneficiary1;
        beneficiaries[1] = beneficiary2;
        amounts[0] = VESTING_AMOUNT;
        startTimes[0] = block.timestamp;
        startTimes[1] = block.timestamp;
        
        vm.prank(owner);
        vm.expectRevert("GensynVestingManager: arrays length mismatch");
        vestingManager.createMultipleVestingWallets(beneficiaries, amounts, startTimes);
    }
}
