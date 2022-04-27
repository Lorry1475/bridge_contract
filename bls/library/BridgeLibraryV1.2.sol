// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BridgeLibrary {
    struct Block{
        uint256 proposeId;
        bytes transactions;
    }

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
    struct CommitteeSign {
        bytes sign;
        address signAddress;
    }
    struct Rollup {
        uint256 bridgeBlock;
        bytes block;
       CommitteeSign[] committeeSigns;
    }

    function decodeTransactions(bytes memory _data)
        internal
        pure
        returns (Transaction[] memory)
    {
        Transaction[] memory _transactions = abi.decode(_data, (Transaction[]));
        return _transactions;
    }


      function decodeBlock(bytes memory _data)
        internal
        pure
        returns (Block memory)
    {
        Block memory _block = abi.decode(_data, (Block));
        return _block;
    }

    // function decodeTransactions(bytes memory _data)
    //     internal
    //     pure
    //     returns (Block memory)
    // {
    //     Block memory _block = abi.decode(_data, (Block));
    //     return _block;
    // }
    
    function getSaltHash(bytes memory salt)
        internal
        pure
        returns (bytes32)
    {

        bytes32 saltHash = keccak256(salt);
        return saltHash;
    }

    function getRollupHash(Rollup memory _rollup,bytes memory salt)
        internal
        pure
        returns (bytes32)
    {
        bytes32 saltHash = getSaltHash(salt);
        bytes32 rollupHash = keccak256(
            abi.encode(saltHash, _rollup.bridgeBlock,_rollup.block)
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
