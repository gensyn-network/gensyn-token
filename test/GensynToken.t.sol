// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

// Inheritance
import {GensynTokenBehavior} from "./GensynTokenBehaviour.t.sol";

// Logging
// import {console2} from "forge-std/console2.sol";

contract GensynTokenTest is GensynTokenBehavior {
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

        // Initialize constants
        initialSupply = gensynTokenProxy.INITIAL_SUPPLY();
    }
}
