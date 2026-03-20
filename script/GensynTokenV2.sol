// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Broadcaster} from "../src/utils/Utils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {GensynToken, GensynTokenV2} from "src/GensynTokenV2.sol";

contract GensynToken_Script is Broadcaster {

    function run() external broadcast returns (
        TimelockController timelock,
        GensynTokenV2 gensynTokenV2Implementation,
        GensynTokenV2 gensynTokenV2Proxy
    ) {
        
        uint timelockMinDelay = ???;
        
        address[] memory timelockProposers = new address[](1);
        timelockProposers[0] = ???;

        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // allow anyone to execute

        address timelockAdmin = address(0); // renounce admin role to prevent centralization
        
        address gensynTokenRecipient = 0x000000000000000000000000000000000000dEaD;

        // Deploy Timelock
        timelock = new TimelockController({
            minDelay: timelockMinDelay,
            proposers: timelockProposers,
            executors: timelockExecutors,
            admin: timelockAdmin
        });

        // Deploy new implementation
        gensynTokenV2Implementation = new GensynTokenV2();

        // Deploy and Initialize new Proxy
        gensynTokenV2Proxy = GensynTokenV2(
            address(
                new ERC1967Proxy({
                    implementation: address(gensynTokenV2Implementation),
                    _data: abi.encodeCall(
                        GensynToken.initialize, (
                            address(timelock), // admin_
                            gensynTokenRecipient // recipient_
                        )
                    )
                })
            )
        );

        // Re-initialize
        gensynTokenV2Proxy.reinitializeV2({
            _recipient: gensynTokenRecipient
        });
    }
}
