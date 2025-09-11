// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GensynVestingWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GensynToken.sol";

/**
 * @title GensynVestingManager
 * @dev Manages vesting schedules for Gensyn token holders
 * @notice This contract creates and manages individual vesting wallets for team members and insiders
 */
contract GensynVestingManager is Ownable {
    GensynToken public immutable gensynToken;
    
    // Vesting parameters
    uint256 public constant CLIFF_DURATION = 365 days; // 1 year cliff
    uint256 public constant VESTING_DURATION = 3 * 365 days; // 3 years total vesting
    uint256 public constant VESTING_PERIOD = 30 days; // Monthly vesting
    
    // Events
    event VestingWalletCreated(
        address indexed beneficiary, 
        address indexed vestingWallet, 
        uint256 amount, 
        uint256 startTime
    );
    event TokensAllocated(address indexed beneficiary, uint256 amount);
    
    // Mapping to track vesting wallets for each beneficiary
    mapping(address => address[]) public vestingWallets;
    mapping(address => uint256) public totalAllocated;
    
    constructor(
        address _gensynToken,
        address initialOwner
    ) Ownable(initialOwner) {
        gensynToken = GensynToken(_gensynToken);
    }
    
    /**
     * @dev Create a vesting wallet for a beneficiary
     * @param beneficiary The address that will receive the vested tokens
     * @param amount The total amount of tokens to vest
     * @param startTime The start time for the vesting schedule (0 for current time)
     * @return vestingWallet The address of the created vesting wallet
     */
    function createVestingWallet(
        address beneficiary,
        uint256 amount,
        uint256 startTime
    ) public onlyOwner returns (address vestingWallet) {
        return _createVestingWallet(beneficiary, amount, startTime);
    }
    
    /**
     * @dev Internal function to create a vesting wallet
     */
    function _createVestingWallet(
        address beneficiary,
        uint256 amount,
        uint256 startTime
    ) internal returns (address vestingWallet) {
        require(beneficiary != address(0), "GensynVestingManager: beneficiary cannot be zero address");
        require(amount > 0, "GensynVestingManager: amount must be greater than 0");
        
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        
        // Create the vesting wallet with cliff
        vestingWallet = address(new GensynVestingWallet(
            beneficiary,
            uint64(startTime),
            uint64(VESTING_DURATION),
            uint64(CLIFF_DURATION)
        ));
        
        // Transfer tokens to the vesting wallet
        require(
            gensynToken.transferFrom(msg.sender, vestingWallet, amount),
            "GensynVestingManager: token transfer failed"
        );
        
        // Track the vesting wallet
        vestingWallets[beneficiary].push(vestingWallet);
        totalAllocated[beneficiary] += amount;
        
        emit VestingWalletCreated(beneficiary, vestingWallet, amount, startTime);
        emit TokensAllocated(beneficiary, amount);
        
        return vestingWallet;
    }
    
    /**
     * @dev Create multiple vesting wallets for multiple beneficiaries
     * @param beneficiaries Array of beneficiary addresses
     * @param amounts Array of token amounts corresponding to each beneficiary
     * @param startTimes Array of start times for each vesting schedule (0 for current time)
     */
    function createMultipleVestingWallets(
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256[] calldata startTimes
    ) external onlyOwner {
        require(
            beneficiaries.length == amounts.length && amounts.length == startTimes.length,
            "GensynVestingManager: arrays length mismatch"
        );
        
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _createVestingWallet(beneficiaries[i], amounts[i], startTimes[i]);
        }
    }
    
    /**
     * @dev Get all vesting wallets for a beneficiary
     * @param beneficiary The beneficiary address
     * @return Array of vesting wallet addresses
     */
    function getVestingWallets(address beneficiary) external view returns (address[] memory) {
        return vestingWallets[beneficiary];
    }
    
    /**
     * @dev Get the total vested amount available for release for a beneficiary
     * @param beneficiary The beneficiary address
     * @return totalVested The total amount available for release across all wallets
     */
    function getTotalVestedAmount(address beneficiary) external view returns (uint256 totalVested) {
        address[] memory wallets = vestingWallets[beneficiary];
        
        for (uint256 i = 0; i < wallets.length; i++) {
            GensynVestingWallet wallet = GensynVestingWallet(payable(wallets[i]));
            totalVested += wallet.releasable(address(gensynToken));
        }
        
        return totalVested;
    }
    
    /**
     * @dev Release vested tokens from all vesting wallets for a beneficiary
     * @param beneficiary The beneficiary address
     * @return totalReleased The total amount of tokens released
     */
    function releaseAll(address beneficiary) external returns (uint256 totalReleased) {
        address[] memory wallets = vestingWallets[beneficiary];
        require(wallets.length > 0, "GensynVestingManager: no vesting wallets found");
        
        for (uint256 i = 0; i < wallets.length; i++) {
            GensynVestingWallet wallet = GensynVestingWallet(payable(wallets[i]));
            uint256 releasable = wallet.releasable(address(gensynToken));
            
            if (releasable > 0) {
                wallet.release(address(gensynToken));
                totalReleased += releasable;
            }
        }
        
        return totalReleased;
    }
    
    /**
     * @dev Get vesting schedule information for a specific wallet
     * @param vestingWallet The vesting wallet address
     * @return beneficiary The beneficiary address
     * @return start The vesting start time
     * @return cliff The cliff duration
     * @return duration The total vesting duration
     * @return released The amount already released
     * @return releasable The amount currently releasable
     */
    function getVestingInfo(address vestingWallet) external view returns (
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 released,
        uint256 releasable
    ) {
        GensynVestingWallet wallet = GensynVestingWallet(payable(vestingWallet));
        
        beneficiary = wallet.owner();
        start = wallet.start();
        cliff = wallet.cliff();
        duration = wallet.duration();
        released = wallet.released(address(gensynToken));
        releasable = wallet.releasable(address(gensynToken));
        
        return (beneficiary, start, cliff, duration, released, releasable);
    }
}
