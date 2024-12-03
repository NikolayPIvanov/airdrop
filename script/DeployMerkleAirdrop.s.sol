// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {PurToken} from "../src/PurToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    function run() public returns (MerkleAirdrop airdrop, PurToken token) {
        vm.startBroadcast();

        token = new PurToken();
        airdrop = new MerkleAirdrop(token, ROOT);

        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        token.transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
    }
}
