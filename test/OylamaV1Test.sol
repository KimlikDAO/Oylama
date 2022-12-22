// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IOylama} from "contracts/IOylama.sol";
import {OYLAMA_V1, OylamaV1} from "contracts/OylamaV1.sol";
import {Oylama} from "contracts/Oylama.sol";
import {DEV_KASASI, OYLAMA, OYLAMA_DEPLOYER} from "interfaces/Addresses.sol";

contract MockOylamaV2 is IOylama {
    function versionHash() external pure returns (bytes32) {
        return keccak256("OylamaV2");
    }

    function migrateToCode(IOylama codeAddress) external {}
}

contract MockBadOylamaV2 is IOylama {
    function versionHash() external pure returns (bytes32) {
        return keccak256("OylamaV2-typo");
    }

    function migrateToCode(IOylama codeAddress) external {}
}

contract OylamaV1Test is Test {
    IOylama private oylama;
    IOylama private oylamaV1;

    function setUp() public {
        vm.startPrank(OYLAMA_DEPLOYER);
        oylama = IOylama(address(new Oylama()));
        oylamaV1 = new OylamaV1();
        vm.stopPrank();
    }

    function testAddressConsistency() public {
        assertEq(address(oylama), OYLAMA);
        assertEq(address(oylamaV1), OYLAMA_V1);
    }

    function testMigrateToCode() public {
        assertEq(oylama.versionHash(), keccak256("OylamaV1"));

        IOylama badOylamaV2 = new MockBadOylamaV2();
        vm.expectRevert();
        oylama.migrateToCode(badOylamaV2);
        vm.prank(DEV_KASASI);
        vm.expectRevert();
        oylama.migrateToCode(badOylamaV2);

        MockOylamaV2 oylamaV2 = new MockOylamaV2();
        vm.expectRevert();
        oylama.migrateToCode(oylamaV2);
        vm.prank(DEV_KASASI);
        oylama.migrateToCode(oylamaV2);
    }
}
