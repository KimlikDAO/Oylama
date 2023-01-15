// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {CODE_SLOT} from "interfaces/ERC1967.sol";
import {DEV_KASASI} from "interfaces/Addresses.sol";
import {IOylama} from "./IOylama.sol";

address constant OYLAMA_V1 = 0xf90E90314a140D6dfB92F0585176985B04659Da5;

contract OylamaV1 is IOylama {
    /**
     * As of OylamaV1, the entire authority of Oylama is delegated to
     * `DEV_KASASI`. In roughly 7 migrations, the entire authority will
     * be back to the TCKO holders.
     *
     * @param target           Address of the contract we'd like to call
     * @param data             The calldata (including the selector) to be sent
     *                         to the target.
     */
    function callTarget(address target, bytes calldata data) external {
        require(msg.sender == DEV_KASASI);
        (bool success, ) = target.call(data);
        require(success);
    }

    function migrateToCode(IOylama newCode) external override {
        require(msg.sender == DEV_KASASI);
        require(
            // keccak256("OylamaV2")
            newCode.versionHash() ==
                0x4290d6a1b6d740f23ccc384ba6018214b01666264bfbfbb57554a50d102a063f
        );
        assembly {
            sstore(CODE_SLOT, newCode)
        }
    }

    function versionHash() external pure override returns (bytes32) {
        // keccak256("OylamaV1")
        return
            0x2ebcd3dad633011bca307c5ca6ad84a8fac491a68c8a3104470dc58a85c91f53;
    }
}
