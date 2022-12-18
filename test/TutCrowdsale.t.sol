// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/SimulaToken.sol";
import "src/TutCrowdsale.sol";
import "forge-std/StdCheats.sol";
import "forge-std/StdUtils.sol";

contract TestTutCrowdsale is Test {
    SimulaToken token;
    TutCrowdsale sale;
    address public  owner;
    

    function setUp() public {

        owner = msg.sender;
        address   bob = vm.addr(1);
        vm.prank(address(bob));
        vm.deal( address(bob), 1000 ether);
        
        
        uint256 rate = 600; 
        //address wallet = address(0); 
        //SimulaToken _token, 
        uint256 cap = 42e18;
        uint256 openingTime = 10000;
        uint256 closingTime = 80000;
        uint256 goal = 4200e18;
        

        token = new SimulaToken();
        
        sale  = new TutCrowdsale(rate,
                                bob,
                                token,
                                cap,
                                openingTime,
                                closingTime,
                                goal
        ); 
        
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

    
    
}
