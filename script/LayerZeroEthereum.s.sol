// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {Broadcaster} from "../src/utils/Utils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {BridgedGensynToken} from "src/BridgedGensynToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IOAppCore {
    function setDelegate(address _delegate) external;
}

contract TrialRun_Script is Broadcaster {

    // Same across both chains
    address constant PORTO = 0x1234567890AbcdEF1234567890aBcdef12345678; // dummy address
    address constant ANTONIO_EOA = 0x8601E191c5257e4ccCe7a36AAD0AD0bB1d5adB63;

    // Ethereum Mainnet
    address constant BRIDGED_GENSYN_TOKEN_SAFE = 0x90442673dae1b1572a3D994A4D795c8977A97ECD;
    TimelockController constant BRIDGED_GENSYN_TOKEN_TIMELOCK = TimelockController(payable(0x78541D1CE97f2F354582344f8319E4D7EF2037FF));
    BridgedGensynToken constant BRIDGED_GENSYN_TOKEN = BridgedGensynToken(0x4d7078DDd6cCFED2F85dB5B7D3Ff16828d378d48);
    address constant BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER = 0x44A39B6b0F544F7f1b0624d312eccD995433A3e4;

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

    // Ethereum Mainnet Helpers
    function _setup() internal returns (TimelockController adapterTimelock) {

        // 1. Deploy AdapterTimelock
        adapterTimelock = new TimelockController({
            minDelay: 7 days,
            proposers: _buildSingletonArray(PORTO),
            executors: _buildSingletonArray(address(0)), // allow anyone to execute
            admin: address(0) // renounce admin role to prevent centralization
        });

        // 2. Transfer BridgedGensynTokenMintBurnOFTAdapter `owner` and `delegate` to the AdapterTimelock
        IOAppCore(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).setDelegate({
            _delegate: address(adapterTimelock)
        });
        Ownable(BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER).transferOwnership({
            newOwner: address(adapterTimelock)
        });

        // 3. Schedule Proposal 1
        BRIDGED_GENSYN_TOKEN_TIMELOCK.scheduleBatch({
            targets: _proposal1Targets(),
            values: _proposal1Values(),
            payloads: _proposal1Calldatas(),
            predecessor: bytes32(0),
            salt: bytes32(0),
            delay: 7 days
        });

        // 4. Schedule Proposal 2
        BRIDGED_GENSYN_TOKEN_TIMELOCK.schedule({
            target: address(BRIDGED_GENSYN_TOKEN),
            value: 0,
            data: abi.encodeCall(
                IAccessControl.grantRole,
                (
                    BRIDGED_GENSYN_TOKEN.DEFAULT_ADMIN_ROLE(),
                    ANTONIO_EOA
                )
            ),
            predecessor: bytes32(0),
            salt: bytes32(0),
            delay: 7 days
        });
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
                    IAccessControl.grantRole,
                    (
                        BRIDGED_GENSYN_TOKEN.DEFAULT_ADMIN_ROLE(),
                        ANTONIO_EOA
                    )
                ),
                predecessor: bytes32(0),
                salt: bytes32(0)
            })
        });
    }

    function _validate() internal {

    }

    function _buildSingletonArray(address element) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = element;
    }

    function _proposal1Targets() internal pure returns (address[] memory targets) {

        // Initialize targets
        targets = new address[](4);

        // Build targets
        targets[0] = address(BRIDGED_GENSYN_TOKEN_TIMELOCK);
        targets[1] =  address(BRIDGED_GENSYN_TOKEN_TIMELOCK);
        targets[2] =  address(BRIDGED_GENSYN_TOKEN_TIMELOCK);
        targets[3] =  address(BRIDGED_GENSYN_TOKEN_TIMELOCK);
    }

    function _proposal1Values() internal pure returns (uint[] memory values) {

        // Initialize values
        values = new uint[](4);

        // Build values
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
    }

    function _proposal1Calldatas() internal view returns (bytes[] memory calldatas) {

        // Initialize targets
        calldatas = new bytes[](4);

        // Build calldatas
        calldatas[0] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN.MINTER_ROLE(),
                BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER
            )
        );
        calldatas[1] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN.BURNER_ROLE(),
                BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER
            )
        );
        calldatas[2] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(),
                PORTO
            )
        );
        calldatas[3] = abi.encodeCall(
            IAccessControl.revokeRole,
            (
                BRIDGED_GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(),
                BRIDGED_GENSYN_TOKEN_SAFE
            )
        );
    }

}
