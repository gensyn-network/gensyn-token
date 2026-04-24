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
        uint256 timelockMinDelay = 7 days;

        address gensynSafeAddress = 0x90442673dae1b1572a3D994A4D795c8977A97ECD;

        address[] memory timelockProposers = new address[](1);
        timelockProposers[0] = gensynSafeAddress;

        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // allow anyone to execute

        address timelockAdmin = address(0); // renounce admin role to prevent centralization

        address gensynTokenRecipient = 0x000000000000000000000000000000000000dEaD;

        // Deploy Timelock
        timelock = new TimelockController({
            minDelay: timelockMinDelay, proposers: timelockProposers, executors: timelockExecutors, admin: timelockAdmin
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
                            address(timelock), // admin_
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
