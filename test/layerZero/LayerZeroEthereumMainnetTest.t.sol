// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_EthereumMainnet_Utils} from "src/utils/layerZero/LayerZeroEthereumMainnetUtils.sol";
import {Test} from "forge-std/Test.sol";

// Interfaces
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract LayerZero_EthereumMainnet_Test is LayerZero_EthereumMainnet_Utils, Test {
    // Tests
    function test_LayerZero_EthereumMainnet() external {
        // Fork Ethereum Mainnet
        vm.createSelectFork("ethereum-mainnet", 24_769_641);

        // Start Prank
        vm.startPrank(ANTONIO_EOA);

        // Validate before
        _validateBefore();

        // Setup
        TimelockController adapterTimelock = _setup({delegate: ANTONIO_EOA, scheduler: BRIDGED_GENSYN_TOKEN_SAFE});

        // Skip Timelock's minimum delay
        skip(BRIDGED_GENSYN_TOKEN_TIMELOCK.getMinDelay());

        // Execute
        _execute();

        // Validate after
        _validateAfter({adapterTimelock: address(adapterTimelock)});
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

    function _validateBefore() internal {

        // Validate adapter delegate & owner
        assertEq(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER.delegate(), ANTONIO_EOA);
        assertEq(Ownable(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).owner(), ANTONIO_EOA);

        // Validate adapter token roles
        assertFalse(
            BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.MINTER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER)
        );
        assertFalse(
            BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.BURNER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER)
        );

        // Validate Timelock proposer
        assertTrue(
            BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(
                BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), BRIDGED_GENSYN_TOKEN_SAFE
            )
        );
        assertFalse(BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO));
    }

    function _validateAfter(address adapterTimelock) internal {

        // Validate adapter delegate & owner
        assertEq(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER.delegate(), adapterTimelock);
        assertEq(Ownable(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).owner(), adapterTimelock);

        // Validate adapter token roles
        assertTrue(
            BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.MINTER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER)
        );
        assertTrue(
            BRIDGED_GENSYN_TOKEN.hasRole(BRIDGED_GENSYN_TOKEN.BURNER_ROLE(), BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER)
        );

        // Validate Timelock proposer
        assertFalse(
            BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(
                BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), BRIDGED_GENSYN_TOKEN_SAFE
            )
        );
        assertTrue(BRIDGED_GENSYN_TOKEN_TIMELOCK.hasRole(BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO));
    }
}
