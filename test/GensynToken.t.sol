// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/GensynToken.sol";

contract GensynTokenTest is Test {
    GensynToken public token;
    address public owner;
    address public user1;
    address public user2;
    
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 10**18;
    
    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.prank(owner);
        token = new GensynToken(owner);
    }
    
    function testInitialState() public {
        assertEq(token.name(), "Gensyn");
        assertEq(token.symbol(), "GEN");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
        assertEq(token.owner(), owner);
    }
    
    function testBasicTransfers() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - transferAmount);
    }
    
    function testPauseUnpause() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer tokens to user1 first
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // Pause the contract
        vm.prank(owner);
        token.pause();
        
        // Try to transfer while paused
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);
        
        // Unpause the contract
        vm.prank(owner);
        token.unpause();
        
        // Transfer should work now
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);
        assertEq(token.balanceOf(user2), 100 * 10**18);
    }
    
    function testOnlyOwnerFunctions() public {
        // Non-owner cannot pause
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }

    function testBurn() public {
        uint256 burnAmount = 100 * 10**18;
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialSupply = token.totalSupply();
        
        // Owner burns their own tokens
        vm.prank(owner);
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
        
        // User1 burns their own tokens
        uint256 transferAmount = 1000 * 10**18;
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        vm.prank(user1);
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(user1), transferAmount - burnAmount);
        assertEq(token.totalSupply(), initialSupply - (2 * burnAmount));
    }

    function testVotes() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer tokens to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // User1 should have 0 votes initially (need to self-delegate)
        assertEq(token.getVotes(user1), 0);
        
        // User1 self-delegates
        vm.prank(user1);
        token.delegate(user1);
        
        // User1 should now have voting power equal to their balance
        assertEq(token.getVotes(user1), transferAmount);
        
        // Check delegation
        assertEq(token.delegates(user1), user1);
        
        // Transfer more tokens to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // Voting power should increase
        assertEq(token.getVotes(user1), 2 * transferAmount);
        
        // User1 delegates to user2
        vm.prank(user1);
        token.delegate(user2);
        
        // user1's voting power should go to user2
        assertEq(token.getVotes(user1), 0);
        assertEq(token.getVotes(user2), 2 * transferAmount);
    }

    function testPermit() public {
        // Use a known private key instead of makeAddr
        uint256 ownerPrivateKey = 0x1234;

        // Give the permit owner some tokens
        address permitOwner = vm.addr(ownerPrivateKey);
        vm.prank(owner);
        token.transfer(permitOwner, 1000 * 10**18);

        _permit(ownerPrivateKey, 0);
    }

    function _permit(uint256 ownerPrivateKey, uint256 nonce) internal {
        address permitOwner = vm.addr(ownerPrivateKey);
        uint256 permitAmount = 500 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create the permit signature using vm.sign
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                permitOwner,
                user2, // spender
                permitAmount,
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        
        // Execute permit
        token.permit(permitOwner, user2, permitAmount, deadline, v, r, s);
        
        // Verify permit worked
        assertEq(token.allowance(permitOwner, user2), permitAmount);
        assertEq(token.nonces(permitOwner), nonce + 1);
        
        // Test that user2 can now spend the tokens
        vm.prank(user2);
        token.transferFrom(permitOwner, user2, permitAmount);
        
        assertEq(token.balanceOf(user2), permitAmount);
    }

    function testDelegateBySig() public {
        // Use a known private key instead of makeAddr
        uint256 ownerPrivateKey = 0x1234;

        // Give the delegate owner some tokens
        address delegateOwner = vm.addr(ownerPrivateKey);
        vm.prank(owner);
        token.transfer(delegateOwner, 1000 * 10**18);

        _delegateBySig(ownerPrivateKey, 0);
    }

    function _delegateBySig(uint256 ownerPrivateKey, uint256 nonce) public {
        address delegateOwner = vm.addr(ownerPrivateKey);
        uint256 expiry = block.timestamp + 1 hours;
        
        uint256 delegationAmount = token.balanceOf(delegateOwner);

        // Create the delegateBySig signature using vm.sign
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)"),
                user2, // delegatee
                nonce,
                expiry
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        
        // Execute delegateBySig
        token.delegateBySig(user2, nonce, expiry, v, r, s);
        
        // Verify delegation worked
        assertEq(token.delegates(delegateOwner), user2);
        
        // Voting power should be delegated to user2
        assertEq(token.getVotes(user2), delegationAmount);

        // Nonce should be incremented
        assertEq(token.nonces(delegateOwner), nonce + 1);
    }

    function testDelegateAndPermitShareNonce() public {
        uint256 ownerPrivateKey = 0x1234;

        // Give the delegate owner some tokens
        address delegateOwner = vm.addr(ownerPrivateKey);
        vm.prank(owner);
        token.transfer(delegateOwner, 1000 * 10**18);
        
        // Initial nonce should be 0
        assertEq(token.nonces(delegateOwner), 0);
        
        // Use permit
        _permit(ownerPrivateKey, 0);
        assertEq(token.nonces(delegateOwner), 1);
        
        // Use delegateBySig
        _delegateBySig(ownerPrivateKey, 1);
        assertEq(token.nonces(delegateOwner), 2);
    }
    
    function testBurnFrom() public {
        uint256 transferAmount = 1000 * 10**18;
        uint256 burnAmount = 100 * 10**18;
        
        // Transfer tokens to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // User1 approves user2 to burn tokens
        vm.prank(user1);
        token.approve(user2, burnAmount);
        
        // User2 burns tokens from user1's balance
        vm.prank(user2);
        token.burnFrom(user1, burnAmount);
        
        assertEq(token.balanceOf(user1), transferAmount - burnAmount);
        assertEq(token.allowance(user1, user2), 0); // Allowance should be consumed
    }
    
    function testPauseBlocksTransfers() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer tokens to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // Approve user2 to spend user1's tokens
        vm.prank(user1);
        token.approve(user2, transferAmount);
        
        // Pause the contract
        vm.prank(owner);
        token.pause();
        
        // Direct transfer should fail
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);
        
        // TransferFrom should also fail
        vm.prank(user2);
        vm.expectRevert();
        token.transferFrom(user1, user2, 100 * 10**18);
        
        // Burning should also fail when paused
        vm.prank(user1);
        vm.expectRevert();
        token.burn(100 * 10**18);
    }
    
    function testCannotBurnMoreThanBalance() public {
        uint256 transferAmount = 100 * 10**18;
        uint256 burnAmount = 200 * 10**18;
        
        // Transfer small amount to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // Try to burn more than balance
        vm.prank(user1);
        vm.expectRevert();
        token.burn(burnAmount);
    }
    
    function testUnpauseRestoresNormalOperation() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer tokens to user1
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // Pause the contract
        vm.prank(owner);
        token.pause();
        
        // Verify transfers are blocked
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);
        
        // Unpause the contract
        vm.prank(owner);
        token.unpause();
        
        // All operations should work normally now
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);
        assertEq(token.balanceOf(user2), 100 * 10**18);
        
        // Burning should work
        vm.prank(user1);
        token.burn(50 * 10**18);
        assertEq(token.balanceOf(user1), transferAmount - 100 * 10**18 - 50 * 10**18);
        
        // Voting should work
        vm.prank(user2);
        token.delegate(user2);
        assertEq(token.getVotes(user2), 100 * 10**18);
    }
}
