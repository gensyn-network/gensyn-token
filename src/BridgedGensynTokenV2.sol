// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

// Inheritance
import {BridgedGensynToken} from "./BridgedGensynToken.sol";
import {
    ERC20CappedUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

// Other
import {GensynToken} from "./GensynToken.sol";

/**
 * @title BridgedGensynTokenV2
 * @author Gensyn
 */
contract BridgedGensynTokenV2 is BridgedGensynToken, ERC20CappedUpgradeable {
    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(GensynToken, ERC20CappedUpgradeable)
    {
        super._update(from, to, value);
    }

    function reinitializeV2() external reinitializer(3) {
        __ERC20Capped_init(INITIAL_SUPPLY);
    }
}
