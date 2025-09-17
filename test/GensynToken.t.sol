// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Tester} from "../src/utils/Utils.sol";

// Other
import {GensynToken} from "../src/GensynToken.sol";
import {GensynTokenV2} from "../test/mocks/GensynTokenV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// Logging
// import {console2} from "forge-std/console2.sol";

contract GensynTokenTest is Tester {
    // ===== ERRORS =====
    error InvalidInitialization();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error UUPSUnauthorizedCallContext();
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    // ===== EVENTS =====
    event Upgraded(address indexed implementation);

    // ===== CONSTANTS =====
    uint256 constant MIN_PRIVATE_KEY = 1;
    uint256 constant MAX_PRIVATE_KEY = 115792089237316195423570985008687907852837564279074904382605163141518161494336;

    // ===== ACTORS =====
    address gensyn = makeAddr("gensyn");
    address alice = makeAddr("alice");

    // ===== CONTRACTS =====
    TimelockController timelock;
    GensynToken public gensynTokenImplementation;
    GensynToken public gensynTokenProxy;

    // ===== ROLES =====
    bytes32 defaultAdminRole;

    // ===== OTHER VARS =====
    uint256 initialSupply;

    // ===== SETUP =====
    function setUp() external {
        // Build timelock proposers
        address[] memory timelockProposers = new address[](1);
        timelockProposers[0] = gensyn;

        // Build timelock executors
        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // Note: Anybody can execute

        // Deploy gensyn token
        (timelock, gensynTokenImplementation, gensynTokenProxy) = _deployGensynProtocol({
            timelockMinDelay_: 7 days,
            timelockProposers_: timelockProposers,
            timelockExecutors_: timelockExecutors,
            timelockAdmin_: address(0), // Note: No Admin
            gensynTokenRecipient_: gensyn
        });

        // Initialize roles
        defaultAdminRole = gensynTokenProxy.DEFAULT_ADMIN_ROLE();

        // Initialize constants
        initialSupply = gensynTokenProxy.INITIAL_SUPPLY();
    }

    // ===== ERC20Upgradeable =====

    function test_InitialState() external view {
        assertEq(gensynTokenProxy.name(), "Gensyn", "unexpected name");
        assertEq(gensynTokenProxy.symbol(), "GEN", "unexpected symbol");
        assertEq(gensynTokenProxy.decimals(), 18, "unexpected decimals");
        assertEq(gensynTokenProxy.INITIAL_SUPPLY(), 10_000_000_000e18, "unexpected initial supply");
        assertEq(gensynTokenProxy.totalSupply(), 10_000_000_000e18, "unexpected total supply");
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply, "unexpected recipient balance");
        assertTrue(gensynTokenProxy.hasRole(defaultAdminRole, address(timelock)), "unexpected default admin role");
    }

    function testFuzz_Transfer(address to, uint256 amount) external {
        // Bound
        vm.assume(to != address(0));
        vm.assume(to != gensyn);
        amount = bound(amount, 1, initialSupply);

        // Validate before
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply);
        assertEq(gensynTokenProxy.balanceOf(to), 0);

        // Recipient transfers amount to gensyn
        _useNewSender(gensyn);
        assertTrue(gensynTokenProxy.transfer(to, amount));

        // Validate after
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply - amount);
        assertEq(gensynTokenProxy.balanceOf(to), amount);
    }

    function testFuzz_TransferFrom(address transferrer, uint256 approved, uint256 value) external {
        // Validate transferrer
        vm.assume(transferrer != address(0));
        vm.assume(transferrer != gensyn);

        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply);
        assertEq(gensynTokenProxy.balanceOf(transferrer), 0);

        // Recipient approves transferrer
        _useNewSender(gensyn);
        approved = bound(approved, 1, gensynTokenProxy.balanceOf(gensyn));
        gensynTokenProxy.approve(transferrer, approved);

        // Transferrer cannot transfer more than approved
        _useNewSender(transferrer);
        value = bound(value, approved + 1, type(uint256).max);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, transferrer, approved, value)
        );
        assertFalse(gensynTokenProxy.transferFrom(gensyn, transferrer, value));

        // Transferrer transfers gensyn's tokens
        value = bound(value, 1, approved);
        assertTrue(gensynTokenProxy.transferFrom(gensyn, transferrer, value));

        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply - value);
        assertEq(gensynTokenProxy.balanceOf(transferrer), value);
    }

    // ===== ERC20BurnableUpgradeable =====

    function testFuzz_Burn(uint256 burn) external {
        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply);
        assertEq(gensynTokenProxy.totalSupply(), initialSupply);

        // Recipient cannot burn more than balance
        _useNewSender(gensyn);
        burn = bound(burn, initialSupply + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, gensyn, initialSupply, burn));
        gensynTokenProxy.burn(burn);

        // Recipient burns
        burn = bound(burn, 1, initialSupply);
        gensynTokenProxy.burn(burn);

        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply - burn);
        assertEq(gensynTokenProxy.totalSupply(), initialSupply - burn);
    }

    function testFuzz_BurnFrom(address burner, uint256 approved, uint256 burn) external {
        // Validate burner
        vm.assume(burner != address(0));

        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply);
        assertEq(gensynTokenProxy.totalSupply(), initialSupply);

        // Recipient approves burner
        _useNewSender(gensyn);
        approved = bound(approved, 1, gensynTokenProxy.balanceOf(gensyn));
        gensynTokenProxy.approve(burner, approved);

        // Burner cannot burn more than approved
        _useNewSender(burner);
        burn = bound(burn, approved + 1, type(uint256).max);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, burner, approved, burn)
        );
        gensynTokenProxy.burnFrom(gensyn, burn);

        // Burner burns gensyn's tokens
        burn = bound(burn, 1, approved);
        gensynTokenProxy.burnFrom(gensyn, burn);

        // Validate
        assertEq(gensynTokenProxy.balanceOf(gensyn), initialSupply - burn);
        assertEq(gensynTokenProxy.totalSupply(), initialSupply - burn);
    }

    // ===== ERC20VotesUpgradeable =====

    function testFuzz_Delegate(address user, uint256 amount, address delegatee) external {
        // Bound
        vm.assume(user != address(0));
        vm.assume(user != gensyn);
        amount = bound(amount, 1, initialSupply / 2);
        vm.assume(delegatee != address(0));
        vm.assume(delegatee != user);

        // Recipient transfers tokens to user
        _useNewSender(gensyn);
        assertTrue(gensynTokenProxy.transfer(user, amount));

        // Ensure user has 0 votes (needs to self-delegate)
        assertEq(gensynTokenProxy.getVotes(user), 0);

        // User self-delegates
        _useNewSender(user);
        gensynTokenProxy.delegate(user);

        // Ensure user votes are now equal to his balance
        assertEq(gensynTokenProxy.getVotes(user), amount);

        // Ensure user is his own delegate
        assertEq(gensynTokenProxy.delegates(user), user);

        // Recipient transfers more tokens to user
        _useNewSender(gensyn);
        assertTrue(gensynTokenProxy.transfer(user, amount));

        // Ensure user votes increased
        assertEq(gensynTokenProxy.getVotes(user), 2 * amount);

        // User delegates to delegate
        _useNewSender(user);
        gensynTokenProxy.delegate(delegatee);

        // Ensure user's votes moved to delegate
        assertEq(gensynTokenProxy.getVotes(user), 0);
        assertEq(gensynTokenProxy.getVotes(delegatee), 2 * amount);
    }

    function testFuzz_DelegateBySig(
        uint256 delegatorPrivateKey,
        address delegatee,
        uint256 delegatorBalance,
        uint256 expiry
    ) external {
        // Bound delegator private key
        delegatorPrivateKey = bound(delegatorPrivateKey, MIN_PRIVATE_KEY, MAX_PRIVATE_KEY);

        // Validate delegatee
        vm.assume(delegatee != address(0));

        // Get delegator info
        address delegator = vm.addr(delegatorPrivateKey);
        uint256 delegatorNonce = vm.getNonce(delegator);

        // Recipient gives delegator some tokens
        _useNewSender(gensyn);
        delegatorBalance = bound(delegatorBalance, 1, gensynTokenProxy.balanceOf(gensyn));
        assertTrue(gensynTokenProxy.transfer(delegator, delegatorBalance));

        // Bound expiry
        expiry = bound(expiry, block.timestamp, type(uint256).max);

        // Delegator signs delegation
        (uint8 v, bytes32 r, bytes32 s) = _signDelegation({
            delegatorPrivateKey: delegatorPrivateKey,
            delegatee: delegatee,
            nonce: delegatorNonce,
            expiry: expiry
        });

        // Delegator delegates by sig
        gensynTokenProxy.delegateBySig(delegatee, delegatorNonce, expiry, v, r, s);

        // Validate
        assertEq(gensynTokenProxy.delegates(delegator), delegatee);
        assertEq(gensynTokenProxy.getVotes(delegator), 0);
        assertEq(gensynTokenProxy.getVotes(delegatee), delegatorBalance);
        assertEq(gensynTokenProxy.nonces(delegator), delegatorNonce + 1);
    }

    // ===== ERC20PermitUpgradeable =====

    function testFuzz_Permit(
        uint256 ownerPrivateKey,
        address spender,
        uint256 ownerBalance,
        uint256 value,
        uint256 deadline
    ) external {
        // Bound owner private key
        ownerPrivateKey = bound(ownerPrivateKey, MIN_PRIVATE_KEY, MAX_PRIVATE_KEY);

        // Validate spender
        vm.assume(spender != address(0));
        vm.assume(spender != gensyn);

        // Get owner info
        address owner = vm.addr(ownerPrivateKey);
        uint256 ownerNonce = vm.getNonce(owner);

        // Recipient gives owner some tokens
        _useNewSender(gensyn);
        ownerBalance = bound(value, 1, gensynTokenProxy.balanceOf(gensyn));
        assertTrue(gensynTokenProxy.transfer(owner, ownerBalance));

        // Bound
        value = bound(value, 1, ownerBalance);
        deadline = bound(deadline, block.timestamp, type(uint256).max);

        // Owner signs permit
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(ownerPrivateKey, spender, value, ownerNonce, deadline);

        // Validate permit before
        assertEq(gensynTokenProxy.allowance(owner, spender), 0);
        assertEq(gensynTokenProxy.nonces(owner), ownerNonce);

        // Execute permit
        gensynTokenProxy.permit(owner, spender, value, deadline, v, r, s);

        // Validate permit after
        assertEq(gensynTokenProxy.allowance(owner, spender), value);
        assertEq(gensynTokenProxy.nonces(owner), ownerNonce + 1);

        // Ensure spender can now spend the owner's tokens
        _useNewSender(spender);
        assertTrue(gensynTokenProxy.transferFrom(owner, spender, value));
        assertEq(gensynTokenProxy.balanceOf(spender), value);
    }

    // ===== ERC20VotesUpgradeable & ERC20PermitUpgradeable =====

    function testFuzz_PermitAndDelegateBySigShareNonce(
        uint256 callerPrivateKey,
        address spender,
        uint256 value,
        uint256 deadline,
        address delegatee,
        uint256 expiry
    ) external {
        // Bound caller private key
        callerPrivateKey = bound(callerPrivateKey, MIN_PRIVATE_KEY, MAX_PRIVATE_KEY);
        vm.assume(spender != address(0));
        deadline = bound(deadline, block.timestamp, type(uint256).max);
        expiry = bound(expiry, block.timestamp, type(uint256).max);

        // Get caller info
        address caller = vm.addr(callerPrivateKey);
        uint256 callerNonce = vm.getNonce(caller);

        // Caller permits
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(callerPrivateKey, spender, value, callerNonce, deadline);
        gensynTokenProxy.permit(caller, spender, value, deadline, v, r, s);
        assertEq(gensynTokenProxy.nonces(caller), callerNonce + 1);

        // Caller delegates by sig
        (v, r, s) = _signDelegation({
            delegatorPrivateKey: callerPrivateKey,
            delegatee: delegatee,
            nonce: callerNonce + 1,
            expiry: expiry
        });
        gensynTokenProxy.delegateBySig(delegatee, callerNonce + 1, expiry, v, r, s);
        assertEq(gensynTokenProxy.nonces(caller), callerNonce + 2);
    }

    // ===== AccessControlUpgradeable =====

    function testFuzz_GrantRole(address executor) external {
        // Get example role
        bytes32 EXAMPLE_ROLE = keccak256("EXAMPLE_ROLE");

        // Ensure alice doesn't already have role
        assertFalse(gensynTokenProxy.hasRole(EXAMPLE_ROLE, alice));

        // Ensure Non-Admin cannot grant role
        _useNewSender(gensyn);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, gensyn, defaultAdminRole));
        gensynTokenProxy.grantRole(EXAMPLE_ROLE, alice);

        // Ensure alice still doesn't have role
        assertFalse(gensynTokenProxy.hasRole(EXAMPLE_ROLE, alice));

        // Ensure Admin can grant roles (via timelock)
        _timelockExecute({
            target: address(gensynTokenProxy),
            data: abi.encodeCall(IAccessControl.grantRole, (EXAMPLE_ROLE, alice)),
            executor: executor
        });

        // Ensure alice has role
        assertTrue(gensynTokenProxy.hasRole(EXAMPLE_ROLE, alice));
    }

    // ===== UUPSUpgradeable =====

    function test_Initialize() external {
        // Ensure implementation can't be initialized
        vm.expectRevert(InvalidInitialization.selector);
        gensynTokenImplementation.initialize(gensyn, gensyn);

        // Ensure proxy can't be initialized again
        vm.expectRevert(InvalidInitialization.selector);
        gensynTokenProxy.initialize(gensyn, gensyn);
    }

    function testFuzz_UpgradeToAndCall(uint256 aliceBalance, uint256 newFoo, uint256 newBar, address executor)
        external
    {
        // Ensure V2 doesn't exist yet
        vm.expectRevert();
        GensynTokenV2(address(gensynTokenProxy)).foo();
        vm.expectRevert();
        GensynTokenV2(address(gensynTokenProxy)).bar();
        vm.expectRevert();
        GensynTokenV2(address(gensynTokenProxy)).version();
        vm.expectRevert();
        GensynTokenV2(address(gensynTokenProxy)).setFoo(newFoo);
        vm.expectRevert();
        _useNewSender(address(timelock)); // Note: use admin (to ensure setBar error isn't permission related)
        GensynTokenV2(address(gensynTokenProxy)).setBar(newBar);

        // Deploy new implementation
        address gensynTokenV2 = vm.deployCode("GensynTokenV2.sol");

        // Ensure Admin can't perform upgrades on the current implementation (via timelock)
        bytes32 salt = _setupTimelockExecute({
            target: address(gensynTokenImplementation),
            data: abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (gensynTokenV2, ""))
        });
        _useNewSender(executor);
        vm.expectRevert(abi.encodeWithSelector(UUPSUnauthorizedCallContext.selector));
        timelock.execute({
            target: address(gensynTokenImplementation),
            value: 0,
            payload: abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (gensynTokenV2, "")),
            predecessor: bytes32(0),
            salt: salt
        });

        // Ensure Non-Admin cannot upgrade proxy to new implementation
        _useNewSender(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, alice, defaultAdminRole));
        gensynTokenProxy.upgradeToAndCall(gensynTokenV2, "");

        // Recipient transfers to alice (to check if state persists)
        _useNewSender(gensyn);
        aliceBalance = bound(aliceBalance, 1, gensynTokenProxy.balanceOf(gensyn));
        assertEq(gensynTokenProxy.balanceOf(alice), 0);
        assertTrue(gensynTokenProxy.transfer({to: alice, value: aliceBalance}));
        assertEq(gensynTokenProxy.balanceOf(alice), aliceBalance);

        // Ensure Admin can upgrade proxy to new implementation (via timelock)
        _setupTimelockExecute({
            target: address(gensynTokenProxy),
            data: abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (gensynTokenV2, ""))
        });
        vm.expectEmit(true, true, true, true, address(gensynTokenProxy));
        emit Upgraded(gensynTokenV2);
        _useNewSender(executor);
        timelock.execute({
            target: address(gensynTokenProxy),
            value: 0,
            payload: abi.encodeCall(UUPSUpgradeable.upgradeToAndCall, (gensynTokenV2, "")),
            predecessor: bytes32(0),
            salt: salt
        });

        // Ensure V1 State persisted
        assertEq(gensynTokenProxy.balanceOf(alice), aliceBalance);

        // Ensure V2 exists
        assertEq(GensynTokenV2(address(gensynTokenProxy)).foo(), 0);
        assertEq(GensynTokenV2(address(gensynTokenProxy)).bar(), 0);
        assertEq(GensynTokenV2(address(gensynTokenProxy)).version(), 2);
        GensynTokenV2(address(gensynTokenProxy)).setFoo(newFoo);
        assertEq(GensynTokenV2(address(gensynTokenProxy)).foo(), newFoo);
        _useNewSender(address(timelock));
        GensynTokenV2(address(gensynTokenProxy)).setBar(newBar);
        assertEq(GensynTokenV2(address(gensynTokenProxy)).bar(), newBar);
    }

    // ===== TimelockController =====

    function testFuzz_Timelock(address executor) external {
        // Build proposal to upgrade
        bytes32 TEST_ROLE = keccak256("TEST_ROLE");
        bytes memory data = abi.encodeCall(IAccessControl.grantRole, (TEST_ROLE, alice));
        bytes32 salt = keccak256("salt");
        uint256 minDelay = timelock.getMinDelay();

        // Proposer cannot schedule with delay under minDelay
        _useNewSender(gensyn);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockController.TimelockInsufficientDelay.selector, minDelay - 1, minDelay)
        );
        timelock.schedule({
            target: address(gensynTokenProxy),
            value: 0,
            data: data,
            predecessor: bytes32(0),
            salt: salt,
            delay: minDelay - 1
        });

        // Proposer schedules
        timelock.schedule({
            target: address(gensynTokenProxy),
            value: 0,
            data: data,
            predecessor: bytes32(0),
            salt: salt,
            delay: minDelay
        });

        // Anyone cannot execute before delay has passed
        _useNewSender(executor);
        vm.expectRevert();
        timelock.execute({
            target: address(gensynTokenProxy),
            value: 0,
            payload: data,
            predecessor: bytes32(0),
            salt: salt
        });

        // Validate state before execution
        assertFalse(gensynTokenProxy.hasRole(TEST_ROLE, alice), "alice has role before timelock execution");

        // Anyone can execute after delay has passed
        skip(minDelay);
        timelock.execute({
            target: address(gensynTokenProxy),
            value: 0,
            payload: data,
            predecessor: bytes32(0),
            salt: salt
        });

        // Validate state after execution
        assertTrue(gensynTokenProxy.hasRole(TEST_ROLE, alice), "alice doesn't have role after timelock execution");
    }

    // ===== INTERNAL UTILS =====

    function _timelockExecute(address target, bytes memory data, address executor) internal {
        // Setup timelock execute
        bytes32 salt = _setupTimelockExecute(target, data);

        // Executor executes
        _useNewSender(executor);
        timelock.execute({target: target, value: 0, payload: data, predecessor: bytes32(0), salt: salt});
    }

    function _setupTimelockExecute(address target, bytes memory data) internal returns (bytes32 salt) {
        // Generate salt
        salt = keccak256("salt");
        uint256 delay = timelock.getMinDelay();

        // Proposer schedules
        _useNewSender(gensyn);
        timelock.schedule({target: target, value: 0, data: data, predecessor: bytes32(0), salt: salt, delay: delay});

        // Skip the delay
        skip(delay);
    }

    function _signDelegation(uint256 delegatorPrivateKey, address delegatee, uint256 nonce, uint256 expiry)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // Generate delegation struct hash
        bytes32 delegationStructHash = vm.eip712HashStruct(
            "Delegation(address delegatee,uint256 nonce,uint256 expiry)", abi.encode(delegatee, nonce, expiry)
        );

        // Sign delegation struct hash
        (v, r, s) = _sign(delegatorPrivateKey, delegationStructHash);
    }

    function _signPermit(uint256 ownerPrivateKey, address spender, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // Generate permit struct hash
        bytes32 permitStructHash = vm.eip712HashStruct(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)",
            abi.encode(vm.addr(ownerPrivateKey), spender, value, nonce, deadline)
        );

        // Sign permit struct hash
        (v, r, s) = _sign(ownerPrivateKey, permitStructHash);
    }

    function _sign(uint256 signerPrivateKey, bytes32 structHash)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // Generate digest
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", gensynTokenProxy.DOMAIN_SEPARATOR(), structHash));

        // Sign
        (v, r, s) = vm.sign(signerPrivateKey, digest);
    }
}
