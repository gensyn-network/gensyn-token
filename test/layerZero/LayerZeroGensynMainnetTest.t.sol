// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_GensynMainnet_Utils} from "src/utils/layerZero/LayerZeroGensynMainnetUtils.sol";
import {Test} from "forge-std/Test.sol";

contract LayerZero_GensynMainnet_Test is LayerZero_GensynMainnet_Utils, Test {
    // Tests
    // function test_LayerZero_GensynMainnet() external {
    //     // Fork Gensyn Mainnet
    //     vm.createSelectFork("gensyn-mainnet");

    //     // Start Prank
    //     vm.startPrank(ANTONIO_EOA);

    //     // Setup
    //     _setup();

    //     // Skip Timelock's minimum delay
    //     skip(GENSYN_TOKEN_TIMELOCK.getMinDelay());

    //     // Execute
    //     _execute();

    //     // Validate
    //     _validate();
    // }

    // function _execute() internal {

    //     // 1. Execute Proposal 1
    //     // BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.executeBatch({
    //     //     targets_: ,
    //     //     values_: ,
    //     //     calldatas_:
    //     //         abi.encodeCall(
    //     //             BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET.setBridgeOperational,
    //     //             (false)
    //     //         )
    //     //     ),
    //     //     predecessor_: bytes32(0),
    //     //     salt_: bytes32(0)
    //     // });
    // }

    // function _validateBefore() internal view {

    //     // Validate adapter delegate & owner
    //     // assertEq(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER.delegate(), ANTONIO_EOA);
    //     assertEq(Ownable(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).owner(), ANTONIO_EOA, "_validateBefore: ANTONIO_EOA not the owner of the adapter");

    //     // Validate adapter token roles
    //     assertFalse(
    //         BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.MINTER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER), "_validateBefore: adapter has MINTER_ROLE on the token");
    //     assertFalse(
    //         BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.BURNER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER), "_validateBefore: adapter has BURNER_ROLE on the token"
    //     );

    //     // Validate Timelock proposer
    //     assertTrue(
    //         BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(
    //             BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), BRIDGED_GENSYN_TOKEN_SAFE
    //         ), "_validateBefore: safe not the proposer on the timelock"
    //     );
    //     assertFalse(BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO), "_validateBefore: porto has PROPOSER_ROLE on the timelock");
    // }

    // function _validateAfter(address adapterTimelock) internal view {

    //     // Validate adapter delegate & owner
    //     // assertEq(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER.delegate(), adapterTimelock);
    //     assertEq(Ownable(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).owner(), adapterTimelock, "_validateAfter: adapterTimelock not the owner of the adapter" );

    //     // Validate adapter token roles
    //     assertTrue(
    //         BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.MINTER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER), "_validateAfter: adapter does not have MINTER_ROLE on the token"
    //     );
    //     assertTrue(
    //         BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.BURNER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER), "_validateAfter: adapter does not have BURNER_ROLE on the token"
    //     );

    //     // Validate Timelock proposer
    //     assertFalse(
    //         BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(
    //             BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), BRIDGED_GENSYN_TOKEN_SAFE
    //         ), "_validateAfter: safe still has PROPOSER_ROLE on the timelock"
    //     );
    //     assertTrue(BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO), "_validateAfter: porto does not have PROPOSER_ROLE on the timelock");
    // }
}
