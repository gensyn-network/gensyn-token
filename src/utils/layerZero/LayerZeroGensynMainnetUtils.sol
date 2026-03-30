// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_SharedUtils} from "./LayerZeroSharedUtils.sol";

// Contracts
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {GensynToken} from "src/GensynToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IOAppCoreLike {
    function setDelegate(address _delegate) external;
}

contract LayerZero_GensynMainnet_Utils is LayerZero_SharedUtils {
    // Gensyn Mainnet
    address constant GENSYN_TOKEN_SAFE = 0xed32eF543F86ac51b7BA5615B98B35B90B1a9559;
    TimelockController constant GENSYN_TOKEN_TIMELOCK =
        TimelockController(payable(0xb041762ee4efcA8F9E33e5f67eC0bcDC4cB1a9e9));
    GensynToken constant GENSYN_TOKEN = GensynToken(0x4e742319f6b0FeC4afA504fC8ED3cEAB0fb751A2);
    address constant GENSYN_TOKEN_OFT_ADAPTER = 0x5B90BcB2630ADa13836fb6ebFc9E7c8b4b2cF509;

    // Gensyn Mainnet Helpers
    function _deployAdapterTimelockAndMoveAdapterPermissions() internal returns (TimelockController adapterTimelock) {
        // Ensure script is being run on Ethereum Mainnet
        require(block.chainid == 685_689, "Chain ID not Gensyn Mainnet");

        // 1. Deploy AdapterTimelock
        adapterTimelock = new TimelockController({
            minDelay: 7 days,
            proposers: _buildSingletonArray(PORTO),
            executors: _buildSingletonArray(address(0)), // allow anyone to execute
            admin: address(0) // renounce admin role to prevent centralization
        });

        // 2. Transfer OFTAdapter `owner` and `delegate` to the AdapterTimelock
        IOAppCoreLike(GENSYN_TOKEN_OFT_ADAPTER).setDelegate({_delegate: address(adapterTimelock)});
        Ownable(GENSYN_TOKEN_OFT_ADAPTER).transferOwnership({newOwner: address(adapterTimelock)});
    }

    function _scheduleProposal() internal {
        // 3. Schedule Proposal 1
        GENSYN_TOKEN_TIMELOCK.scheduleBatch({
            targets: proposal1Targets(),
            values: proposal1Values(),
            payloads: proposal1Calldatas(),
            predecessor: bytes32(0),
            salt: bytes32(0),
            delay: GENSYN_TOKEN_TIMELOCK.getMinDelay()
        });
    }

    function proposal1Targets() public pure returns (address[] memory targets) {
        // Initialize targets
        targets = new address[](4);

        // Build targets
        targets[0] = address(GENSYN_TOKEN_TIMELOCK);
        targets[1] = address(GENSYN_TOKEN_TIMELOCK);
        targets[2] = address(GENSYN_TOKEN_TIMELOCK);
        targets[3] = address(GENSYN_TOKEN_TIMELOCK);
    }

    function proposal1Values() public pure returns (uint256[] memory values) {
        // Initialize values
        values = new uint256[](4);

        // Build values
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
    }

    function proposal1Calldatas() public view returns (bytes[] memory calldatas) {
        // Initialize targets
        calldatas = new bytes[](4);

        // Grant PROPOSER_ROLE and CANCELLER_ROLE to PORTO
        calldatas[0] = abi.encodeCall(IAccessControl.grantRole, (GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), PORTO));
        calldatas[1] = abi.encodeCall(IAccessControl.grantRole, (GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), PORTO));

        // Revoke PROPOSER_ROLE and CANCELLER_ROLE from the GENSYN_TOKEN_SAFE
        calldatas[2] =
            abi.encodeCall(IAccessControl.revokeRole, (GENSYN_TOKEN_TIMELOCK.PROPOSER_ROLE(), GENSYN_TOKEN_SAFE));
        calldatas[3] =
            abi.encodeCall(IAccessControl.revokeRole, (GENSYN_TOKEN_TIMELOCK.CANCELLER_ROLE(), GENSYN_TOKEN_SAFE));
    }
}
