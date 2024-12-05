// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    error MerkleAirdrop__ProofInvalid();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    IERC20 private immutable token;
    bytes32 private immutable merkleRoot;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    mapping(address claimer => bool claimed) public claimed;

    event Claim(address indexed account, uint256 amount);

    // some list of addresses
    // allow someone in the list to claim token
    constructor(IERC20 _token, bytes32 _merkleRoot) EIP712("Merkle Airdrop", "1.0.0") {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    /**
     * Claim tokens
     * @param account The address of the claimer which is eligible for airdrop
     * @param amount The amount of token the claimer can receive
     * @param proof The merkle proof array which is used to construct and verify the merkle tree
     */
    function claim(address account, uint256 amount, bytes32[] calldata proof, uint8 v, bytes32 r, bytes32 s) external {
        if (claimed[account]) revert MerkleAirdrop__AlreadyClaimed();

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // It is standard to hash twice to prevent collisions
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert MerkleAirdrop__ProofInvalid();

        claimed[account] = true;
        emit Claim(account, amount);

        token.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address account, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (
            address actualSigner,
            /*ECDSA.RecoverError recoverError*/
            ,
            /*bytes32 signatureLength*/
        ) = ECDSA.tryRecover(messageHash, v, r, s);
        return (actualSigner == account);
    }
}
