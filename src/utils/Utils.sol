// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {CommonBase} from "forge-std/Base.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";

// Other
import {GensynToken} from "../GensynToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

// Todo: generalize with vm.deployCode
abstract contract Deployer is CommonBase {
    function _deployGensynProtocol(
        uint256 timelockMinDelay_,
        address[] memory timelockProposers_,
        address[] memory timelockExecutors_,
        address timelockAdmin_,
        address gensynTokenRecipient_
    )
        internal
        returns (TimelockController timelock, GensynToken gensynTokenImplementation, GensynToken gensynTokenProxy)
    {
        // Deploy Timelock
        timelock = new TimelockController({
            minDelay: timelockMinDelay_,
            proposers: timelockProposers_,
            executors: timelockExecutors_,
            admin: timelockAdmin_
        });

        // Deploy Gensyn Token
        (gensynTokenImplementation, gensynTokenProxy) =
            _deployGensynToken({gensynTokenAdmin_: address(timelock), gensynTokenRecipient_: gensynTokenRecipient_});
    }

    function _deployGensynToken(address gensynTokenAdmin_, address gensynTokenRecipient_)
        internal
        returns (GensynToken gensynTokenImplementation, GensynToken gensynTokenProxy)
    {
        // Deploy new implementation
        gensynTokenImplementation = new GensynToken();

        // Deploy new Proxy
        gensynTokenProxy = GensynToken(
            address(
                new ERC1967Proxy({
                    implementation: address(gensynTokenImplementation),
                    _data: abi.encodeCall(GensynToken.initialize, (gensynTokenAdmin_, gensynTokenRecipient_))
                })
            )
        );
    }
}

abstract contract Broadcaster is Deployer, Script {
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}

abstract contract Tester is Deployer, Test {
    function _useNewSender(address sender) internal {
        vm.stopPrank();
        vm.startPrank(sender);
    }
}
