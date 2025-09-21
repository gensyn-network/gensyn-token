// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Broadcaster} from "../src/utils/Utils.sol";

// Other
import {GensynToken} from "../src/GensynToken.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

// Logging
import {console2} from "forge-std/console2.sol";

contract GensynToken_Script is Broadcaster {
    uint256 constant GENSYN_TESTNET_CHAIN_ID = 685_685;
    // uint256 constant GENSYN_MAINNET_CHAIN_ID = ???;

    function deploy() external broadcast {
        // Get params
        (address gensynTokenTimelockProposer, address gensynTokenRecipient) = _getDeploymentParams();

        // Build timelock proposers
        address[] memory timelockProposers = new address[](1);
        timelockProposers[0] = gensynTokenTimelockProposer;

        // Build timelock executors
        address[] memory timelockExecutors = new address[](1);
        timelockExecutors[0] = address(0); // Note: Anybody can execute

        // Deploy
        (TimelockController timelock, GensynToken gensynTokenImplementation, GensynToken gensynTokenProxy) =
        _deployGensynProtocol({
            timelockMinDelay_: 7 days,
            timelockProposers_: timelockProposers,
            timelockExecutors_: timelockExecutors,
            timelockAdmin_: address(0), // Note: No admin
            gensynTokenRecipient_: gensynTokenRecipient
        });

        // Log
        console2.log("New GensynToken Timelock deployed at:", address(timelock));
        console2.log("New GensynToken Implementation deployed at:", address(gensynTokenImplementation));
        console2.log("New GensynToken Proxy deployed at:", address(gensynTokenProxy));
    }

    // Todo: updates will now be performed via timelock (schedule & execute)
    // function upgrade() external broadcast {
    //     // Get params
    //     (
    //         address gensynTokenProxy,
    //         string memory gensynTokenNewImplementationArtifact,
    //         bytes memory gensynTokenUpgradeCalldata
    //     ) = _getUpgradeParams();

    //     // Deploy new implementation
    //     address newImplementation = vm.deployCode(gensynTokenNewImplementationArtifact);

    //     // Upgrade proxy to new implementation
    //     UUPSUpgradeable(gensynTokenProxy).upgradeToAndCall(newImplementation, gensynTokenUpgradeCalldata);

    //     // Log
    //     console2.log("GensynToken Proxy upgraded to new GensynToken Implementation deployed at:", newImplementation);
    // }

    function _getDeploymentParams()
        internal
        view
        returns (address gensynTokenTimelockProposer, address gensynTokenRecipient)
    {
        if (block.chainid == GENSYN_TESTNET_CHAIN_ID) {
            gensynTokenTimelockProposer = vm.envAddress("GENSYN_TOKEN_TIMELOCK_PROPOSER_TESTNET");
            gensynTokenRecipient = vm.envAddress("GENSYN_TOKEN_RECIPIENT_TESTNET");
        } else {
            revert("Invalid Chain ID");
        }
    }

    // Todo: updates will now be performed via timelock (schedule & execute)
    // function _getUpgradeParams()
    //     internal
    //     view
    //     returns (
    //         address gensynTokenProxy,
    //         string memory gensynTokenNewImplementationArtifact,
    //         bytes memory gensynTokenUpgradeCalldata
    //     )
    // {
    //     if (block.chainid == GENSYN_TESTNET_CHAIN_ID) {
    //         gensynTokenProxy = vm.envAddress("GENSYN_TOKEN_PROXY_TESTNET");
    //         gensynTokenNewImplementationArtifact = vm.envString("GENSYN_TOKEN_NEW_IMPLEMENTATION_ARTIFACT_TESTNET");
    //         gensynTokenUpgradeCalldata = vm.envBytes("GENSYN_TOKEN_UPGRADE_CALLDATA_TESTNET");
    //     } else {
    //         revert("Invalid Chain ID");
    //     }
    // }
}
