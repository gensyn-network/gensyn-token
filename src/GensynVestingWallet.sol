// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

/**
 * @title GensynVestingWallet
 * @dev A vesting wallet with cliff functionality for Gensyn tokens
 * @notice This contract implements a concrete vesting wallet with cliff period
 */
contract GensynVestingWallet is VestingWallet {
    uint64 private immutable _cliff;

    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);

    /**
     * @dev Set the beneficiary, start timestamp, duration, and cliff of the vesting wallet.
     * @param beneficiary The address that will receive the vested tokens
     * @param startTimestamp The timestamp when vesting starts
     * @param durationSeconds The total duration of vesting in seconds
     * @param cliffSeconds The cliff duration in seconds
     */
    constructor(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    ) payable VestingWallet(beneficiary, startTimestamp, durationSeconds) {
        if (cliffSeconds > durationSeconds) {
            revert InvalidCliffDuration(cliffSeconds, durationSeconds);
        }
        _cliff = startTimestamp + cliffSeconds;
    }

    /**
     * @dev Getter for the cliff timestamp.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @dev Virtual implementation of the vesting formula. Returns the amount vested, as a function of time, for
     * an asset given its total historical allocation. Implements cliff functionality.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view override returns (uint256) {
        if (timestamp < cliff()) {
            return 0;
        } else {
            return super._vestingSchedule(totalAllocation, timestamp);
        }
    }
}
