// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__ProofInvalid();
    error MerkleAirdrop__AlreadyClaimed();

    IERC20 private immutable token;
    bytes32 private immutable merkleRoot;
    mapping(address claimer => bool claimed) public claimed;

    event Claim(address indexed account, uint256 amount);

    // some list of addresses
    // allow someone in the list to claim token
    constructor(IERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(address account, uint256 amount, bytes32[] calldata proof) external {
        if (claimed[account]) revert MerkleAirdrop__AlreadyClaimed();

        // It is standard to hash twice to prevent collisions
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encodePacked(account, amount))));

        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert MerkleAirdrop__ProofInvalid();

        claimed[account] = true;
        emit Claim(account, amount);

        token.safeTransfer(account, amount);
    }
}
