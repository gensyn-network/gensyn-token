// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_GensynMainnet_Utils} from "src/utils/layerZero/LayerZeroGensynMainnetUtils.sol";
import {Broadcaster} from "../src/utils/Utils.sol";

contract LayerZero_GensynMainnet_Script is LayerZero_GensynMainnet_Utils, Broadcaster {
    // Scripts
    function run() external broadcast {
        _setup({delegate: ANTONIO_EOA, proposer: GENSYN_TOKEN_SAFE});
    }
}
