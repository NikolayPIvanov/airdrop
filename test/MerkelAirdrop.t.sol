// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PurToken} from "../src/PurToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkelAirdropTest is ZkSyncChainChecker, Test {
    PurToken public token;
    MerkleAirdrop public airdrop;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT = 25 * 1e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT * 4;

    bytes32[] public PROOF = [
        bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
        bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
    ];

    address public user;
    address public gasPayer;
    uint256 public userPrivKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.run();
        } else {
            token = new PurToken();
            airdrop = new MerkleAirdrop(token, ROOT);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, AMOUNT);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);

        console.log(user);

        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);
        vm.stopPrank();

        vm.startPrank(gasPayer);
        airdrop.claim(user, AMOUNT, PROOF, v, r, s);
        vm.stopPrank();

        uint256 endingBalance = token.balanceOf(user);

        assert(endingBalance - startingBalance == AMOUNT);
    }
}
