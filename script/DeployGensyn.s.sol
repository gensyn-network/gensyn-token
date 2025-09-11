// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/GensynToken.sol";
import "../src/GensynVestingManager.sol";
import "../src/MerkleDistributor.sol";

/**
 * @title DeployGensyn
 * @dev Deployment script for the Gensyn token ecosystem
 */
contract DeployGensyn is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the main Gensyn token
        GensynToken gensynToken = new GensynToken(owner);
        console.log("GensynToken deployed at:", address(gensynToken));
        
        // Display deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Deployer:", deployer);
        console.log("Owner:", owner);
        console.log("GensynToken:", address(gensynToken));
        console.log("Total Supply:", gensynToken.totalSupply());
        console.log("==========================");
        
        vm.stopBroadcast();
    }
}
