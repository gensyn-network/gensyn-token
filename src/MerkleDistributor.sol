// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MerkleDistributor
 * @dev A contract for distributing tokens using merkle proofs
 * @notice Allows efficient distribution of tokens to a large number of recipients
 */
contract MerkleDistributor is Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 index, address account, uint256 amount);

    constructor(
        address token_,
        bytes32 merkleRoot_,
        address owner_
    ) Ownable(owner_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), "MerkleDistributor: Transfer failed.");

        emit Claimed(index, account, amount);
    }

    /**
     * @dev Emergency function to withdraw remaining tokens (only owner)
     * @param to The address to send the tokens to
     */
    function emergencyWithdraw(address to) external onlyOwner {
        require(to != address(0), "MerkleDistributor: cannot withdraw to zero address");
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "MerkleDistributor: no tokens to withdraw");
        
        require(IERC20(token).transfer(to, balance), "MerkleDistributor: Transfer failed.");
    }

    /**
     * @dev Get the remaining balance of tokens in the distributor
     * @return The remaining token balance
     */
    function getRemainingBalance() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
