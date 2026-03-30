// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {LayerZero_EthereumMainnet_Utils} from "src/utils/layerZero/LayerZeroEthereumMainnetUtils.sol";
import {Broadcaster} from "../src/utils/Utils.sol";

contract LayerZero_EthereumMainnet_Script is LayerZero_EthereumMainnet_Utils, Broadcaster {
    function run() external broadcast {
        _setup({delegate: ANTONIO_EOA, scheduler: BRIDGED_GENSYN_TOKEN_SAFE});
    }
}
