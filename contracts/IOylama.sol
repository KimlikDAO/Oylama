// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IOylama {
    function versionHash() external pure returns (bytes32);

    function migrateToCode(IOylama codeAddress) external;
}
