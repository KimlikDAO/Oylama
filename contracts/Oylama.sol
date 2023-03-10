// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {CODE_SLOT} from "interfaces/ERC1967.sol";
import {OYLAMA_V1} from "./OylamaV1.sol";

contract Oylama {
    constructor() {
        assembly {
            sstore(CODE_SLOT, OYLAMA_V1)
        }
    }

    fallback() external payable {
        assembly {
            let codeAddress := sload(CODE_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                codeAddress,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
