// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Inheritance
import {CommonBase} from "forge-std/Base.sol";

interface IOAppCoreLike {
    function setDelegate(address _delegate) external;
    function endpoint() external view returns (address);
}

interface ILayerZeroEndpointV2Like {
    function delegates(address oapp) external view returns (address);
}

contract LayerZero_SharedUtils is CommonBase {
    address constant PORTO = 0x1234567890AbcdEF1234567890aBcdef12345678; // dummy address
    address constant ANTONIO_EOA = 0x8601E191c5257e4ccCe7a36AAD0AD0bB1d5adB63;

    function _buildSingletonArray(address element) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = element;
    }

    function _useNewSender(address sender) internal {
        vm.stopPrank();
        vm.startPrank(sender);
    }
}
