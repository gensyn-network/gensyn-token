// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/GensynToken.sol";
import "../src/MerkleDistributor.sol";

contract MerkleDistributorTest is Test {
    GensynToken public token;
    MerkleDistributor public distributor;
    address public owner;
    address public user1;
    address public user2;
    
    uint256 public constant DISTRIBUTION_AMOUNT = 1_000_000 * 10**18;
    
    // Example merkle tree for testing (simplified)
    // In a real scenario, you'd generate this properly with a merkle tree library
    bytes32 public merkleRoot = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
    
    event Claimed(uint256 index, address account, uint256 amount);
    
    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.startPrank(owner);
        token = new GensynToken(owner);
        distributor = new MerkleDistributor(address(token), merkleRoot, owner);
        
        // Transfer tokens to distributor
        token.transfer(address(distributor), DISTRIBUTION_AMOUNT);
        vm.stopPrank();
    }
    
    function testInitialState() public {
        assertEq(distributor.token(), address(token));
        assertEq(distributor.merkleRoot(), merkleRoot);
        assertEq(distributor.owner(), owner);
        assertEq(token.balanceOf(address(distributor)), DISTRIBUTION_AMOUNT);
        assertEq(distributor.getRemainingBalance(), DISTRIBUTION_AMOUNT);
    }
    
    function testCannotClaimWithInvalidProof() public {
        uint256 index = 0;
        address account = user1;
        uint256 amount = 1000 * 10**18;
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = bytes32(0x1111111111111111111111111111111111111111111111111111111111111111);
        
        vm.expectRevert("MerkleDistributor: Invalid proof.");
        distributor.claim(index, account, amount, merkleProof);
    }
    
    function testCannotClaimTwice() public {
        // This test requires a valid merkle proof which is complex to generate
        // In practice, you'd use a merkle tree library to generate valid proofs
        // For now, we'll test the claim checking logic by manipulating storage
        
        uint256 index = 0;
        
        // Manually set the claim (simulating a successful claim)
        vm.store(
            address(distributor),
            keccak256(abi.encode(index / 256, uint256(1))), // Simplified storage slot calculation
            bytes32(uint256(1 << (index % 256)))
        );
        
        assertTrue(distributor.isClaimed(index));
        
        bytes32[] memory merkleProof = new bytes32[](0);
        vm.expectRevert("MerkleDistributor: Drop already claimed.");
        distributor.claim(index, user1, 1000, merkleProof);
    }
    
    function testEmergencyWithdraw() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 distributorBalance = token.balanceOf(address(distributor));
        
        vm.prank(owner);
        distributor.emergencyWithdraw(owner);
        
        assertEq(token.balanceOf(owner), initialBalance + distributorBalance);
        assertEq(token.balanceOf(address(distributor)), 0);
        assertEq(distributor.getRemainingBalance(), 0);
    }
    
    function testOnlyOwnerCanEmergencyWithdraw() public {
        vm.prank(user1);
        vm.expectRevert();
        distributor.emergencyWithdraw(user1);
    }
    
    function testCannotEmergencyWithdrawToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("MerkleDistributor: cannot withdraw to zero address");
        distributor.emergencyWithdraw(address(0));
    }
    
    function testIsClaimedBitMapping() public {
        // Test the bit mapping logic
        assertFalse(distributor.isClaimed(0));
        assertFalse(distributor.isClaimed(1));
        assertFalse(distributor.isClaimed(255));
        assertFalse(distributor.isClaimed(256));
        
        // The actual claim function would set these bits,
        // but we're testing the reading logic here
    }
    
    function testGetRemainingBalance() public {
        assertEq(distributor.getRemainingBalance(), DISTRIBUTION_AMOUNT);
        
        // Simulate some tokens being distributed
        vm.prank(address(distributor));
        token.transfer(user1, 100 * 10**18);
        
        assertEq(distributor.getRemainingBalance(), DISTRIBUTION_AMOUNT - 100 * 10**18);
    }
    
    function testSimpleAirdropWorkflow() public {
        // This test demonstrates a complete airdrop workflow with real merkle proofs
        
        // 1. Set up airdrop recipients and amounts
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        
        uint256 aliceAmount = 1000 * 10**18;
        uint256 bobAmount = 2000 * 10**18;
        uint256 totalAmount = aliceAmount + bobAmount;
        
        // 2. Create simple 2-person merkle tree
        // Tree structure:
        //       Root
        //      /    \
        //  Alice    Bob
        //
        // Each user needs the other's leaf as proof to verify against the root
        bytes32 leafAlice = keccak256(abi.encodePacked(uint256(0), alice, aliceAmount));
        bytes32 leafBob = keccak256(abi.encodePacked(uint256(1), bob, bobAmount));
        
        // Create root (simple case: just hash the two leaves in order)
        bytes32 airdropRoot = keccak256(abi.encodePacked(leafAlice, leafBob));
        
        // 3. Deploy and fund distributor
        MerkleDistributor airdrop = new MerkleDistributor(
            address(token),
            airdropRoot,
            owner
        );
        
        vm.prank(owner);
        token.transfer(address(airdrop), totalAmount);
        
        // 4. Verify initial state
        assertEq(token.balanceOf(address(airdrop)), totalAmount);
        assertEq(airdrop.getRemainingBalance(), totalAmount);
        assertEq(airdrop.merkleRoot(), airdropRoot);
        
        // 5. Test Alice's claim (index 0)
        {
            // Alice's proof: she needs Bob's leaf to prove the root
            bytes32[] memory aliceProof = new bytes32[](1);
            aliceProof[0] = leafBob;
            
            uint256 initialBalance = token.balanceOf(alice);
            
            vm.expectEmit(true, true, true, true);
            emit Claimed(0, alice, aliceAmount);
            
            airdrop.claim(0, alice, aliceAmount, aliceProof);
            
            assertEq(token.balanceOf(alice), initialBalance + aliceAmount);
            assertTrue(airdrop.isClaimed(0));
            assertEq(airdrop.getRemainingBalance(), totalAmount - aliceAmount);
        }
        
        // 6. Test Bob's claim (index 1)
        {
            // Bob's proof: he needs Alice's leaf to prove the root
            bytes32[] memory bobProof = new bytes32[](1);
            bobProof[0] = leafAlice;
            
            uint256 initialBalance = token.balanceOf(bob);
            
            vm.expectEmit(true, true, true, true);
            emit Claimed(1, bob, bobAmount);
            
            airdrop.claim(1, bob, bobAmount, bobProof);
            
            assertEq(token.balanceOf(bob), initialBalance + bobAmount);
            assertTrue(airdrop.isClaimed(1));
            assertEq(airdrop.getRemainingBalance(), 0);
        }
        
        // 7. Verify double claim protection
        {
            bytes32[] memory aliceProof = new bytes32[](1);
            aliceProof[0] = leafBob;
            
            vm.expectRevert("MerkleDistributor: Drop already claimed.");
            airdrop.claim(0, alice, aliceAmount, aliceProof);
        }
        
        // 8. Verify final state
        assertTrue(airdrop.isClaimed(0));
        assertTrue(airdrop.isClaimed(1));
        assertEq(airdrop.getRemainingBalance(), 0);
        
        // This demonstrates the complete airdrop lifecycle:
        // - Create merkle tree with eligible recipients
        // - Deploy distributor with merkle root
        // - Fund the distributor
        // - Users claim with valid merkle proofs
        // - Prevent double claiming
}
}
