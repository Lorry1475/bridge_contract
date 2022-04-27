// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BridgeLibraryV1 {
    struct Transaction {
        uint256 amount;
        address payable account;
        address erc20Token;
    }
    struct VerifyMultiSign {
        bytes aggregatedPublicKey;
        bytes partPublicKey;
        bytes message;
        bytes partSignature;
        uint256 signersBitmask;
    }
    struct Rollup {
        uint256 bridgeBlock;
        bytes pool;
        VerifyMultiSign verifyMultiSign;
    }

}
