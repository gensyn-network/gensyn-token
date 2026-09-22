// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

// Inheritance
import {GensynTokenBehavior} from "./GensynTokenBehaviour.t.sol";

// Contracts
import {GensynToken} from "../src/GensynToken.sol";
import {BridgedGensynToken} from "src/BridgedGensynToken.sol";
import {BridgedGensynTokenV2} from "src/BridgedGensynTokenV2.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    ERC20CappedUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

contract BridgedGensynTokenV2TestFork is GensynTokenBehavior {
    // forge-lint: disable-next-line(unsafe-cheatcode)
    string networksConfigToml = vm.readFile("config/networks.toml");
    string networkAlias = "ethereum-mainnet";

    // ===== ACTORS =====
    address minter = makeAddr("minter");

    // ===== SETUP =====
    function setUp() external {
        // Get block number
        uint256 blockNumber = _readUint("block");

        // Fork (from block number)
        vm.createSelectFork(networkAlias, blockNumber);

        timelock = TimelockController(payable(_readAddress("timelock")));
        gensynTokenProxy = GensynToken(_readAddress("ai"));
        gensyn = _readAddress("porto");

        // Initialize constants
        initialSupply = gensynTokenProxy.INITIAL_SUPPLY();

        gensynTokenImplementation = GensynToken(address(new BridgedGensynTokenV2()));

        _timelockExecute({
            target: address(gensynTokenProxy),
            data: abi.encodeCall(
                UUPSUpgradeable.upgradeToAndCall,
                (
                    address(gensynTokenImplementation), // newImplementation
                    (abi.encodeCall(BridgedGensynTokenV2.reinitializeV2, ())) // data
                )
            ),
            executor: gensyn
        });

        minter = gensyn;
        _timelockExecute({
            target: address(gensynTokenProxy),
            data: abi.encodeCall(AccessControl.grantRole, (keccak256("MINTER_ROLE"), minter)),
            executor: gensyn
        });

        BridgedGensynToken(address(gensynTokenProxy)).mint(gensyn, 1e18);
    }

    function test_Reverts_MintPastLimit() external {
        uint256 totalSupply = gensynTokenProxy.totalSupply();
        uint256 amount = initialSupply + 1 - totalSupply;
        _useNewSender(minter);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20CappedUpgradeable.ERC20ExceededCap.selector, initialSupply + 1, initialSupply)
        );
        BridgedGensynToken(address(gensynTokenProxy)).mint(gensyn, amount);
    }

    // UTILS

    function _readAddress(string memory tag) internal view returns (address) {
        return abi.decode(vm.parseToml(networksConfigToml, string.concat(".", networkAlias, ".", tag)), (address));
    }

    function _readUint(string memory tag) internal view returns (uint256) {
        return abi.decode(vm.parseToml(networksConfigToml, string.concat(".", networkAlias, ".", tag)), (uint256));
    }

    function _beforeBurnTest() internal override {}

    function _beforeBurnFromTest() internal override {}
}
