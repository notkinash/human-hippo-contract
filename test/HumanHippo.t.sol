// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/HumanHippo.sol";
import "../src/LosCubs.sol";

contract HumanHippoTest is Test {
    HumanHippo public humanHippo;
    LosCubs public losCubs;

    function setUp() public {
        string memory metadata = "ipfs://test/";
        losCubs = new LosCubs(metadata);
        humanHippo = new HumanHippo(
            1,
            35 ether,
            777,
            msg.sender,
            500,
            20 minutes,
            metadata,
            address(losCubs)
        );
        humanHippo.toggleMint();
    }

    // Whitelist

    function testWhitelistHolder() public {
        vm.prank(address(this));
        losCubs.give(msg.sender, 1);
        assertEq(humanHippo.whitelisted(msg.sender), true);
    }

    function testWhitelistAdded() public {
        vm.prank(address(this));
        humanHippo.whitelistAdd(msg.sender);
        assertEq(humanHippo.whitelisted(msg.sender), true);
    }

    function testFailWhitelist() public {
        assertEq(humanHippo.whitelisted(msg.sender), true);
    }

    // Whitelist mint

    function testWhitelistMintSingle() public {
        testWhitelistHolder();
        uint256 quantity = 1;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    function testWhitelistMintMultiple() public {
        testWhitelistHolder();
        uint256 quantity = 5;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    function testFailWhitelistMintMultiple() public {
        uint256 quantity = 5;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    // Public mint

    function testPublicMintSingle() public {
        vm.prank(address(this));
        humanHippo.togglePublicSale();
        vm.warp(block.timestamp + 21 minutes);
        uint256 quantity = 1;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    function testPublicMintMultiple() public {
        vm.prank(address(this));
        humanHippo.togglePublicSale();
        vm.warp(block.timestamp + 21 minutes);
        uint256 quantity = 777;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    function testFailPublicMintMultiple() public {
        vm.prank(address(this));
        humanHippo.togglePublicSale();
        uint256 quantity = 5;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }

    function testFailPausePublicMintMultiple() public {
        vm.prank(address(this));
        humanHippo.togglePublicSale();
        vm.warp(block.timestamp + 21 minutes);
        vm.prank(address(this));
        humanHippo.togglePause();
        uint256 quantity = 5;
        uint256 price = humanHippo.mintPrice() * quantity;
        vm.prank(msg.sender);
        humanHippo.mint{value: price}(quantity);
        assertEq(humanHippo.balanceOf(msg.sender), quantity);
    }
}