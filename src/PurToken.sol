// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PurToken is ERC20, Ownable {
    constructor() ERC20("PurToken", "Pur") Ownable(msg.sender) {}

    function mint(address to, uint256 value) external virtual onlyOwner {
        _mint(to, value);
    }
}