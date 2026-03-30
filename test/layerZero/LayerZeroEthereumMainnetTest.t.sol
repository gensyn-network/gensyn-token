// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_EthereumMainnet_Utils} from "src/utils/layerZero/LayerZeroEthereumMainnetUtils.sol";
import {Test} from "forge-std/Test.sol";

// Interfaces
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract LayerZero_EthereumMainnet_Test is LayerZero_EthereumMainnet_Utils, Test {
    // Tests
    function test_LayerZero_EthereumMainnet() external {
        // Fork Ethereum Mainnet
        vm.createSelectFork("ethereum-mainnet", 24_769_641);

        // Start Prank
        vm.startPrank(ANTONIO_EOA);

        // Setup
        _setup({delegate: ANTONIO_EOA, scheduler: BRIDGED_GENSYN_TOKEN_SAFE});

        // Skip Timelock's minimum delay
        skip(BRIDGED_GENSYN_TOKEN_TIMELOCK.getMinDelay());

        // Execute
        _execute();

        // Validate
        _validate();
    }

    function _execute() internal {
        // 1. Execute Proposal 1
        BRIDGED_GENSYN_TOKEN_TIMELOCK.executeBatch({
            targets: _proposal1Targets(),
            values: _proposal1Values(),
            payloads: _proposal1Calldatas(),
            predecessor: bytes32(0),
            salt: bytes32(0)
        });

        // 2. Cancel Proposal 2
        BRIDGED_GENSYN_TOKEN_TIMELOCK.cancel({
            id: BRIDGED_GENSYN_TOKEN_TIMELOCK.hashOperation({
                target: address(BRIDGED_GENSYN_TOKEN),
                value: 0,
                data: abi.encodeCall(
                    IAccessControl.grantRole, (BRIDGED_GENSYN_TOKEN.DEFAULT_ADMIN_ROLE(), ANTONIO_EOA)
                ),
                predecessor: bytes32(0),
                salt: bytes32(0)
            })
        });
    }

    function _validate() internal {}
}
