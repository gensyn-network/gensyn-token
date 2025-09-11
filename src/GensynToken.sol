// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title GensynToken
 * @dev Burnable ERC20 token with ownership, pausability, permit, and voting support
 */
contract GensynToken is ERC20Burnable, Ownable, ERC20Pausable, ERC20Permit, ERC20Votes {
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 10**18; // 10 billion tokens
    
    constructor(
        address initialOwner
    ) ERC20("Gensyn", "GEN") Ownable(initialOwner) ERC20Permit("Gensyn") {
        _mint(initialOwner, TOTAL_SUPPLY);
    }
    
    /**
     * @dev Override transfer to respect pause functionality
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom to respect pause functionality
     */
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev Pause the contract (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ==== Explicit overrides ====
    
    /// @inheritdoc ERC20Permit
    function nonces(address account) public view override(ERC20Permit, Nonces) returns (uint256) {
        return ERC20Permit.nonces(account);
    }

    /**
     * @dev Override _update to respect pause functionality. Calls ERC20Votes _update
     */
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable, ERC20Votes) whenNotPaused {
        ERC20Votes._update(from, to, value);
    }
}
