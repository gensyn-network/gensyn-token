// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Broadcaster} from "../src/utils/Utils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

// Interfaces
// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract TrialRun_Script is Broadcaster {

    // Same across both chains
    address constant PORTO = 0x1234567890AbcdEF1234567890aBcdef12345678; // dummy address
    address constant ANTONIO_EOA = 0x8601E191c5257e4ccCe7a36AAD0AD0bB1d5adB63;
    
    // Gensyn Mainnet
    // address constant GENSYN_TOKEN_SAFE;
    // address constant GENSYN_TOKEN_TIMELOCK;
    // address constant GENSYN_TOKEN;
    // address constant GENSYN_TOKEN_OFT_ADAPTER;

    // Tests
    function testEndToEnd() external {
        _setup();
        vm.warp(block.timestamp + 7 days);
        _execute();
        _validate();
    }
    
    // Scripts
    function run() external broadcast {
        _setup();
    }

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

    function _validate() internal {

    }

    function _buildSingletonArray(address element) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = element;
    }
}
