// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DEV_KASASI, OYLAMA, OYLAMA_DEPLOYER} from "interfaces/Addresses.sol";
import {IOylama} from "contracts/IOylama.sol";
import {OYLAMA_V1, OylamaV1} from "contracts/OylamaV1.sol";
import {Oylama} from "contracts/Oylama.sol";

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

contract MockTCKT {
    event PriceChange(address indexed token, uint256 price);
    event PremiumChange(uint256 premium);

    function updatePricesBulk(uint256 premium, uint256[5] calldata prices)
        external
    {
        require(msg.sender == OYLAMA);
        emit PremiumChange(premium);
        for (uint256 i = 0; i < 5; ++i) {
            if (prices[i] == 0) break;
            address token = address(uint160(prices[i]));
            uint256 price = prices[i] >> 160;
            emit PriceChange(token, price);
        }
    }

    function updatePrice(uint256 priceAndToken) external {
        require(msg.sender == OYLAMA);
        address token = address(uint160(priceAndToken));
        uint256 price = priceAndToken >> 160;
        console.log("PriceChange(%s, %s)", token, price);
        emit PriceChange(token, price);
    }
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

    function testAddressConsistency() external {
        assertEq(address(oylama), OYLAMA);
        assertEq(address(oylamaV1), OYLAMA_V1);
    }

    function testMigrateToCode() external {
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

    event PriceChange(address indexed token, uint256 price);

    function testCallTarget() external {
        MockTCKT tckt = new MockTCKT();

        vm.expectEmit(true, false, false, true, address(tckt));
        emit PriceChange(vm.addr(1), 10);

        vm.prank(DEV_KASASI);
        OylamaV1(address(oylama)).callTarget(
            address(tckt),
            abi.encodeWithSignature(
                "updatePrice(uint256)",
                (uint256(10) << 160) | uint160(vm.addr(1))
            )
        );
    }
}
