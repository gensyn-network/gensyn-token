// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_EthereumMainnet_Utils} from "src/utils/layerZero/LayerZeroEthereumMainnetUtils.sol";
import {Broadcaster} from "src/utils/Utils.sol";

contract LayerZero_EthereumMainnet_Script is LayerZero_EthereumMainnet_Utils, Broadcaster {
    // Note: The safe actions will be performed separately (via the Gnosis Safe UI)
    function run() external broadcast {
        _deployAdapterTimelockAndMoveAdapterPermissions();
    }
}
