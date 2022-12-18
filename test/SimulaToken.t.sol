// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/SimulaToken.sol";

contract TestSimulaToken is Test {
    SimulaToken token;

    function setUp() public {
        token = new SimulaToken();
    }

    function testName() public {
        assertEq(token.name(), "SimulaToken", "ok");
    }

    function testSymbol() public {
        assertEq(token.symbol(), "SML", "ok");
    }

    
    function testTotalSupply() public {
        
        assertEq(token.totalSupply(), 100000000000000000000);
    }

    uint256 amount      = 10000;
    uint256 maxAmount   = 49999;
    function testMint() public {
        token.mint{value: amount}(address(1),1e18);
        assertEq(token.totalSupply(), 101000000000000000000);

        token.mint{value: maxAmount}(address(1),1e18);
        assertEq(token.totalSupply(), 102000000000000000000);

        // TODO howto caths the request error
        //token.mint{value: 1000000}(address(1),1e18);
        //assertEq(token.totalSupply(), 102000000000000000000);

        //token.mint{value: 70000}(address(1),1e18);
        //assertEq(token.totalSupply(), 101000000000000000000);
    }
    
}
