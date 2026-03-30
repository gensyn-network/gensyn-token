// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_GensynMainnet_Utils} from "src/utils/layerZero/LayerZeroGensynMainnetUtils.sol";
import {Test} from "forge-std/Test.sol";

// Interfaces
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

interface IOAppCoreLike {
    function endpoint() external view returns (address);
}

interface ILayerZeroEndpointV2Like {
    function delegates(address oapp) external view returns (address);
}

contract LayerZero_GensynMainnet_Test is LayerZero_GensynMainnet_Utils, Test {
    // Tests
    function test_LayerZero_GensynMainnet() external {
        // Fork Gensyn Mainnet
        vm.createSelectFork("gensyn-mainnet");

        // Validate before
        _validateBefore();

        // Deploy Adapter Timelock and Move Adapter Permissions (from ANTONIO_EOA)
        _useNewSender(ANTONIO_EOA);
        TimelockController adapterTimelock = _deployAdapterTimelockAndMoveAdapterPermissions();

        // Schedule Proposal 1 (from GENSYN_TOKEN_SAFE)
        _useNewSender(GENSYN_TOKEN_SAFE);
        _scheduleProposal();

        // Skip Timelock's minimum delay
        skip(GENSYN_TOKEN_TIMELOCK.getMinDelay());

        // Execute
        _execute();

        // Validate after
        _validateAfter({adapterTimelock: address(adapterTimelock)});
    }

    function _execute() internal {
        // Execute Proposal 1
        GENSYN_TOKEN_TIMELOCK.executeBatch({
            targets: proposal1Targets(),
            values: proposal1Values(),
            payloads: proposal1Calldatas(),
            predecessor: bytes32(0),
            salt: bytes32(0)
        });
    }

    function _validateBefore() internal view {
        // Validate adapter delegate & owner
        // assertEq(GENSYN_TOKEN_OFT_ADAPTER.delegate(), ANTONIO_EOA);
        assertEq(
            Ownable(GENSYN_TOKEN_OFT_ADAPTER).owner(),
            ANTONIO_EOA,
            "_validateBefore: ANTONIO_EOA not the owner of the adapter"
        );

        // Validate Timelock proposer
        assertTrue(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), GENSYN_TOKEN_SAFE),
            "_validateBefore: safe not the proposer on the timelock"
        );
        assertFalse(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO),
            "_validateBefore: porto has PROPOSER_ROLE on the timelock"
        );

        // Validate Timelock canceller
        assertTrue(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), GENSYN_TOKEN_SAFE),
            "_validateBefore: safe not the canceller on the timelock"
        );
        assertFalse(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), PORTO),
            "_validateBefore: porto has CANCELLER_ROLE on the timelock"
        );
    }

    function _validateAfter(address adapterTimelock) internal view {
        // Validate adapter delegate
        address endpoint = IOAppCoreLike(address(GENSYN_TOKEN_OFT_ADAPTER)).endpoint();
        address delegate = ILayerZeroEndpointV2Like(endpoint).delegates(address(GENSYN_TOKEN_OFT_ADAPTER));
        assertEq(delegate, adapterTimelock);

        // Validate adapter owner
        assertEq(
            Ownable(GENSYN_TOKEN_OFT_ADAPTER).owner(),
            adapterTimelock,
            "_validateAfter: adapterTimelock not the owner of the adapter"
        );

        // Validate Timelock proposer
        assertFalse(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), GENSYN_TOKEN_SAFE),
            "_validateAfter: safe still has PROPOSER_ROLE on the timelock"
        );
        assertTrue(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO),
            "_validateAfter: porto does not have PROPOSER_ROLE on the timelock"
        );

        // Validate Timelock canceller
        assertFalse(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), GENSYN_TOKEN_SAFE),
            "_validateAfter: safe still has CANCELLER_ROLE on the timelock"
        );
        assertTrue(
            GENSYN_TOKEN_TIMELOCK.hasRole(GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), PORTO),
            "_validateAfter: porto does not have CANCELLER_ROLE on the timelock"
        );
    }
}
