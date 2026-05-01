// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZKFLToken is ERC20, Ownable {
    constructor() ERC20("ZK Federated Learning Token", "ZKFL") Ownable(msg.sender) {
        // Mint 1 million tokens to the deployer
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
