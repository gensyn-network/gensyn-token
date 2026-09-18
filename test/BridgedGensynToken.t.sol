// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

// Inheritance
import {GensynTokenBehavior} from "./GensynTokenBehaviour.t.sol";

// Contracts
import {GensynToken} from "../src/GensynToken.sol";
import {BridgedGensynToken} from "src/BridgedGensynToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Logging
// import {console2} from "forge-std/console2.sol";

contract BridgedGensynTokenTest is GensynTokenBehavior {
    // ===== ACTORS =====
    address minter = makeAddr("minter");

    // ===== SETUP =====
    function setUp() external {
        // Build timelock proposers
        address[] memory timelockProposers = new address[](1);
        timelockProposers[0] = gensyn;

        // Build timelock executors
        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // Note: Anybody can execute

        uint256 timelockMinDelay = 7 days;

        address timelockAdmin = address(0); // renounce admin role to prevent centralization

        // Deploy Timelock
        timelock = new TimelockController({
            minDelay: timelockMinDelay, proposers: timelockProposers, executors: timelockExecutors, admin: timelockAdmin
        });

        gensynTokenImplementation = GensynToken(address(new BridgedGensynToken()));

        address gensynTokenRecipient = 0x000000000000000000000000000000000000dEaD;

        gensynTokenProxy = GensynToken(
            address(
                new ERC1967Proxy({
                    implementation: address(gensynTokenImplementation),
                    _data: abi.encodeCall(
                        GensynToken.initialize,
                        (
                            address(timelock), // admin_
                            gensynTokenRecipient // recipient_
                        )
                    )
                })
            )
        );

        // Re-initialize Proxy
        BridgedGensynToken(address(gensynTokenProxy)).reinitialize({_recipient: gensynTokenRecipient});

        // Initialize constants
        initialSupply = gensynTokenProxy.INITIAL_SUPPLY();

        assertEq(gensynTokenProxy.totalSupply(), 0, "unexpected total supply");
        assertEq(gensynTokenProxy.balanceOf(gensyn), 0, "unexpected recipient balance");

        _timelockExecute({
            target: address(gensynTokenProxy),
            data: abi.encodeCall(AccessControl.grantRole, (keccak256("MINTER_ROLE"), minter)),
            executor: gensyn
        });

        _useNewSender(minter);
        BridgedGensynToken(address(gensynTokenProxy)).mint(gensyn, initialSupply);
    }

    // TODO test mint with no minter
}
