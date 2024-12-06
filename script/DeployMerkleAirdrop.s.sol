// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {PurToken} from "../src/PurToken.sol";
import {MerkleAirdrop, IERC20} from "../src/MerkleAirdrop.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    // 4 users, 25 Bagel tokens each
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    // Deploy the airdrop contract and bagel token contract
    function deployMerkleAirdrop() public returns (MerkleAirdrop, PurToken) {
        vm.startBroadcast();
        PurToken token = new PurToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(IERC20(token), ROOT);
        // Send Bagel tokens -> Merkle Air Drop contract
        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        IERC20(token).transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, token);
    }

    function run() external returns (MerkleAirdrop, PurToken) {
        return deployMerkleAirdrop();
    }
}
