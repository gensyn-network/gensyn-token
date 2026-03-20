// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {GensynToken} from "./GensynToken.sol";
import {IMintableBurnable} from "lib/devtools/packages/oft-evm/contracts/interfaces/IMintableBurnable.sol";

/**
 * @title BridgedGensynToken
 * @author Gensyn
 * @notice BridgedGensynToken adds minting and burning capabilities to GensynToken
 */
/**
 * Deployment Plan:
 * 1. Deploy `BridgedGensynToken`
 * 2. Later, deploy `MintBurnOFTAdapter` (with `BridgedGensynToken` as `token` and `minterBurner`)
 * 3. Grant `MINTER_ROLE` and `BURNER_ROLE` to `MintBurnOFTAdapter` (in `BridgedGensynToken`)
 */
contract BridgedGensynToken is GensynToken, IMintableBurnable {
    /// @notice Role allowed to mint tokens to any address
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role allowed to burn tokens from any address
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Burns the INITIAL_SUPPLY minted during `initialize()`, so that the total supply starts at 0.
    /// @dev Meant to be called right after `initialize()`.
    function reinitialize(address _recipient) external reinitializer(2) {
        // Burn initial supply from recipient
        _burn(_recipient, INITIAL_SUPPLY);

        // Ensure total supply is zero after upgrade
        /// @dev This is the bridged token, so its supply should start at 0
        assert(totalSupply() == 0);
    }

    /// @inheritdoc IMintableBurnable
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) returns (bool success) {
        _mint(_to, _amount);
        success = true;
    }

    /// @inheritdoc IMintableBurnable
    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) returns (bool success) {
        _burn(_from, _amount);
        success = true;
    }
}
