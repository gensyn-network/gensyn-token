// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract TrialRun_Script is Broadcaster {

    // Same across both chains
    address constant PORTO;
    address constant ANTONIO_EOA;

    // Ethereum Mainnet
    address constant BRIDGED_GENSYN_TOKEN_SAFE_ETHEREUM_MAINNET;
    address constant BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET;
    address constant BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET;
    address constant BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET;
    
    // Gensyn Mainnet
    address constant GENSYN_TOKEN_SAFE_GENSYN_MAINNET;
    address constant GENSYN_TOKEN_TIMELOCK_GENSYN_MAINNET;
    address constant GENSYN_TOKEN_GENSYN_MAINNET;
    address constant GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET;

    // Tests
    function testEndToEndEthereumMainnet() external {
        _setupEthereumMainnet();
        _skipTime();
        _executeEthereumMainnet();
        _validateEthereumMainnet();
    }

    function testEndToEndGensynMainnet() external {
        _setupGensynMainnet();
        _skipTime();
        _executeGensynMainnet();
        _validateGensynMainnet();
    }
    
    // Scripts
    function runEthereumMainnet() external broadcast {
        _setupEthereumMainnet();
    }

    function runGensynMainnet() external broadcast {
        _setupGensynMainnet();
    }

    // Ethereum Mainnet Helpers
    function _setupEthereumMainnet() internal returns (TimelockController adapterTimelock) {

        // 1. Deploy AdapterTimelock
        adapterTimelock = new TimelockController({
            minDelay: 7 days,
            proposers: _buildSingletonArray(PORTO),
            executors: _buildSingletonArray(address(0)), // allow anyone to execute
            admin: address(0) // renounce admin role to prevent centralization
        });

        // 2. Transfer BridgedGensynTokenMintBurnOFTAdapter `owner` and `delegate` to the AdapterTimelock
        BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET.setDelegate({
            delegate_: address(adapterTimelock)
        });
        BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET.transferOwnership({
            newOwner_: address(adapterTimelock)
        });

        // 3. Schedule Proposal 1
        BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.scheduleBatch({
            targets_: _ethereumMainnetProposal1Targets(),
            values_: _ethereumMainnetProposal1Values(),
            calldatas_: _ethereumMainnetProposal1Calldatas(),
            predecessor_: bytes32(0),
            salt_: bytes32(0),
            delay_: 7 days
        });

        // 4. Schedule Proposal 2
        BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.schedule({
            target_: BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET,
            value_: 0,
            calldata_: abi.encodeCall(
                IAccessControl.grantRole,
                (
                    BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET.DEFAULT_ADMIN_ROLE(),
                    ANTONIO_EOA
                )
            );,
            predecessor_: bytes32(0),
            salt_: bytes32(0),
            delay_: 7 days
        });
    }

    function _executeEthereumMainnet() internal {

        // 1. Execute Proposal 1
        BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.executeBatch({
            targets_: _ethereumMainnetProposal1Targets(),
            values_: _ethereumMainnetProposal1Values(),
            calldatas_: _ethereumMainnetProposal1Calldatas(),
            predecessor_: bytes32(0),
            salt_: bytes32(0)
        });

        // 2. Cancel Proposal 2
        BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.cancel({
            target_: BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET,
            value_: 0,
            calldata_: abi.encodeCall(
                IAccessControl.grantRole,
                (
                    BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET.DEFAULT_ADMIN_ROLE(),
                    ANTONIO_EOA
                )
            );,
            predecessor_: bytes32(0),
            salt_: bytes32(0)
        });
    }

    function _validateEthereumMainnet() internal {

    }

    // Gensyn Mainnet Helpers
    function _setupGensynMainnet() internal returns (TimelockController adapterTimelock) {

        // 1. Deploy AdapterTimelock
        adapterTimelock = new TimelockController({
            minDelay: 7 days,
            proposers: _buildSingletonArray(),
            executors: _buildSingletonArray(address(0)), // allow anyone to execute
            admin: address(0) // renounce admin role to prevent centralization
        });

        // 2. Transfer OFTAdapter `owner` and `delegate` to the AdapterTimelock
        GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.setDelegate({
            delegate_: address(adapterTimelock)
        });
        GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.transferOwnership({
            newOwner_: address(adapterTimelock)
        });

        // 3. Schedule Proposal 1
        GENSYN_TOKEN_TIMELOCK_GENSYN_MAINNET.scheduleBatch({
            targets_: ,
            values_: ,
            calldatas_:
                abi.encodeCall(
                    GENSYN_TOKEN_OFT_ADAPTER_GENSYN_MAINNET.setBridgeOperational,
                    (false)
                )
            ),
            predecessor_: bytes32(0),
            salt_: bytes32(0),
            delay_: 7 days
        });
    }

    function _executeGensynMainnet() internal {

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

    function _validateGensynMainnet() internal {

    }

    function _buildSingletonArray(address element) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = element;
    }

    function _ethereumMainnetProposal1Targets() internal pure returns (address targets) {

        // Initialize targets
        targets = new address[](4);

        // Build targets
        targets[0] = BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET;
        targets[1] = BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET;
        targets[2] = BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET;
        targets[3] = BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET;
    }

    function _ethereumMainnetProposal1Values() internal pure returns (address values) {

        // Initialize values
        values = new address[](4);

        // Build values
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
    }

    function _ethereumMainnetProposal1Calldatas() internal pure returns (bytes[] calldatas) {

        // Initialize targets
        calldatas = new bytes[](4);

        // Build calldatas
        calldatas[0] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET.MINTER_ROLE(),
                BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET
            )
        );
        calldatas[1] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN_ETHEREUM_MAINNET.BURNER_ROLE(),
                BRIDGED_GENSYN_TOKEN_MINT_BURN_OFT_ADAPTER_ETHEREUM_MAINNET
            )
        );
        calldatas[2] = abi.encodeCall(
            IAccessControl.grantRole,
            (
                BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.PROPOSER_ROLE(),
                PORTO
            )
        );
        calldatas[3] = abi.encodeCall(
            IAccessControl.revokeRole,
            (
                BRIDGED_GENSYN_TOKEN_TIMELOCK_ETHEREUM_MAINNET.PROPOSER_ROLE(),
                BRIDGED_GENSYN_TOKEN_SAFE_ETHEREUM_MAINNET
            )
        );
    }

}
