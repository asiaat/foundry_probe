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

    function testMint() public {
        token.mint(msg.sender,1e18);
        assertEq(token.totalSupply(), 101000000000000000000);
    }
    
}
