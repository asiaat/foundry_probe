// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract SimulaToken is Ownable, ERC20Pausable {


    constructor() ERC20("SimulaToken", "SML") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public  payable{
        require(msg.value == 10000);
        _mint(to, amount);
    }
}