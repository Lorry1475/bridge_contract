// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BridgeLibrary {
    struct Transaction {
        uint256 amount;
        address payable account;
        address erc20Token;
    }
    struct CommitteeSign {
        bytes sign;
        address signAddress;
    }
    struct Rollup {
        Transaction[] transactions;
        CommitteeSign[] committeeSigns;
        uint256 bridgeBlock;
    }

    function getTransactionsHash(Transaction[] memory _transactions,bytes memory salt)
        internal
        pure
        returns (bytes32)
    {

        for (uint256 i = 0; i < _transactions.length; i++) {
            salt = abi.encodePacked(
                salt,
                _transactions[i].amount,
                _transactions[i].account,
                _transactions[i].erc20Token
            );
       }
        bytes32 txhash = keccak256(salt);
        return txhash;
    }

    function getRollupHash(Rollup memory _rollup,bytes memory salt)
        internal
        pure
        returns (bytes32)
    {
        bytes32 txhash = getTransactionsHash(_rollup.transactions,salt);
        bytes32 rollupHash = keccak256(
            abi.encodePacked(txhash, _rollup.bridgeBlock)
        );
        return rollupHash;
    }

    function verificationRollup(Rollup memory _rollup,bytes memory salt)
        internal
        pure
        returns (bool)
    {
        bytes32 rollupHash = getRollupHash(_rollup,salt);

        for (uint256 i = 0; i < _rollup.committeeSigns.length; i++) {
            bool effectiveness = isValidSignature(
                rollupHash,
                _rollup.committeeSigns[i].signAddress,
                _rollup.committeeSigns[i].sign
            );
            if (!effectiveness) {
                return false;
            }
        }
        return true;
    }

    function isValidSignature(
        bytes32 _hash,
        address _user,
        bytes memory _sign
    ) internal pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        _hash = keccak256(abi.encodePacked(prefix, _hash));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            let temp := mload(0)
            let temp2 := mload(32)
            let temp3 := mload(64)
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := and(mload(add(_sign, 65)), 255)
            mstore(0, temp)
            mstore(32, temp2)
            mstore(64, temp3)
        }
        if (v < 27) {
            v += 27;
        }
        address _recover = ecrecover(_hash, v, r, s);
        return (_user == _recover);
    }
}
