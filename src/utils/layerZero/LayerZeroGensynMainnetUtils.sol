// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_SharedUtils} from "./LayerZeroSharedUtils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {GensynToken} from "src/GensynToken.sol";

contract LayerZero_GensynMainnet_Utils is LayerZero_SharedUtils {
    // Gensyn Mainnet
    address constant GENSYN_TOKEN_SAFE = 0xed32eF543F86ac51b7BA5615B98B35B90B1a9559;
    TimelockController constant GENSYN_TOKEN_TIMELOCK =
        TimelockController(payable(0xb041762ee4efcA8F9E33e5f67eC0bcDC4cB1a9e9));
    GensynToken constant GENSYN_TOKEN = GensynToken(0x4e742319f6b0FeC4afA504fC8ED3cEAB0fb751A2);
    address constant GENSYN_TOKEN_OFT_ADAPTER = 0x5B90BcB2630ADa13836fb6ebFc9E7c8b4b2cF509;

    // Gensyn Mainnet Helpers
    function _setup() internal returns (TimelockController adapterTimelock) {

        // // 1. Deploy AdapterTimelock
        // adapterTimelock = new TimelockController({
        //     minDelay: 7 days,
        //     proposers: _buildSingletonArray(),
        //     executors: _buildSingletonArray(address(0)), // allow anyone to execute
        //     admin: address(0) // renounce admin role to prevent centralization
        // });

        // // 2. Transfer OFTAdapter `owner` and `delegate` to the AdapterTimelock
        // GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.setDelegate({
        //     delegate_: address(adapterTimelock)
        // });
        // GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.transferOwnership({
        //     newOwner_: address(adapterTimelock)
        // });

        // // 3. Schedule Proposal 1
        // GENSYN_TOKEN_TIMELOCK_GENSYN_MAINNET.scheduleBatch({
        //     targets_: ,
        //     values_: ,
        //     calldatas_:
        //         abi.encodeCall(
        //             GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.setBridgeOperational,
        //             (false)
        //         )
        //     ),
        //     predecessor_: bytes32(0),
        //     salt_: bytes32(0),
        //     delay_: 7 days
        // });
    }
}
