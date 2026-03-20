// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {GensynToken} from "./GensynToken.sol";
import {IMintableBurnable} from "lib/devtools/packages/oft-evm/contracts/interfaces/IMintableBurnable.sol";

// Plan:
// 1. Deploy GensynTokenV2
// 2. Later, deploy MintBurnOFTAdapter (with GensynTokenV2 as token and minterBurner)
// 3. Grant MINTER_ROLE and BURNER_ROLE to MintBurnOFTAdapter (in GensynTokenV2)
contract GensynTokenV2 is GensynToken, IMintableBurnable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function reinitializeV2(address _recipient) external reinitializer(2) {
        _burn(_recipient, INITIAL_SUPPLY);
        assert(totalSupply() == 0);
    }

    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) returns (bool success) {
        _mint(_to, _amount);
        success = true;
    }

    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) returns (bool success) {
        _burn(_from, _amount);
        success = true;
    }
}
