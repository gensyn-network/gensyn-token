// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_GensynMainnet_Utils} from "src/utils/layerZero/LayerZeroGensynMainnetUtils.sol";
import {Test} from "forge-std/Test.sol";

contract LayerZero_GensynMainnet_Test is LayerZero_GensynMainnet_Utils, Test {
    // Tests
    function test_LayerZero_GensynMainnet() external {
        // Fork Gensyn Mainnet
        vm.createSelectFork("gensyn-mainnet");

        // Start Prank
        vm.startPrank(ANTONIO_EOA);

        // Setup
        _setup();

        // Skip Timelock's minimum delay
        skip(GENSYN_TOKEN_TIMELOCK.getMinDelay());

        // Execute
        _execute();

        // Validate
        _validate();
    }

    function _execute() internal {

        // 1. Execute Proposal 1
        // BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.executeBatch({
        //     targets_: ,
        //     values_: ,
        //     calldatas_:
        //         abi.encodeCall(
        //             BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET.setBridgeOperational,
        //             (false)
        //         )
        //     ),
        //     predecessor_: bytes32(0),
        //     salt_: bytes32(0)
        // });
    }

    function _validate() internal {}
}
