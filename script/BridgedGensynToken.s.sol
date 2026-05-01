// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Broadcaster} from "../src/utils/Utils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {GensynToken, BridgedGensynToken} from "src/BridgedGensynToken.sol";

contract GensynToken_Script is Broadcaster {
    function run()
        external
        broadcast
        returns (
            TimelockController timelock,
            BridgedGensynToken bridgedGensynTokenImplementation,
            BridgedGensynToken bridgedGensynTokenProxy
        )
    {
        // Pick temp admin (will be renounced later)
        address tempAdmin = 0x4eE2Ef21c70b00d1D3E613f1a311670565C8C556;

        // Pick timelock proposers
        address[] memory timelockProposers = new address[](0);

        // Pick timelock executors
        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // allow anyone to execute

        // Pick gensyn token recipient
        address gensynTokenRecipient = 0x000000000000000000000000000000000000dEaD;

        // Deploy Timelock
        timelock = new TimelockController({
            minDelay: 7 days, proposers: timelockProposers, executors: timelockExecutors, admin: tempAdmin
        });

        // Deploy new implementation
        bridgedGensynTokenImplementation = new BridgedGensynToken();

        // Deploy and Initialize new Proxy
        bridgedGensynTokenProxy = BridgedGensynToken(
            address(
                new ERC1967Proxy({
                    implementation: address(bridgedGensynTokenImplementation),
                    _data: abi.encodeCall(
                        GensynToken.initialize,
                        (
                            tempAdmin, // admin_
                            gensynTokenRecipient // recipient_
                        )
                    )
                })
            )
        );

        // Re-initialize Proxy
        bridgedGensynTokenProxy.reinitialize({_recipient: gensynTokenRecipient});
    }
}
