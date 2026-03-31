// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_GensynMainnet_Utils} from "src/utils/layerZero/LayerZeroGensynMainnetUtils.sol";
import {Broadcaster} from "src/utils/Utils.sol";

contract LayerZero_GensynMainnet_Script is LayerZero_GensynMainnet_Utils, Broadcaster {
    // Note: The safe actions will be performed separately (via the Gnosis Safe UI)
    function run() external broadcast {
        _deployAdapterTimelockAndMoveAdapterPermissions();
    }
}
