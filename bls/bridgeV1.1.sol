// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./library/BridgeLibraryV1.1.sol";
import "./assets.sol";
import "./BlsSignature.sol";

contract BridgeV1_1 is Asset, BlsSignature {
    uint256 public committeeNum = 0;
    bool private init;
    address public EthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Minimum token transfer quantity
    uint256 minAmount = 100000000000000;
    bytes private salt = "v1.0";
    /// @dev Members of the Governance Committee,
    /// who will undertake the token transfer verification between two different networks, dfinity and Ethereum
    mapping(address => BridgeAccount) public committee;
    mapping(address => bool) public accountLockout;
    mapping(address => bool) public assetTable;
   // bytes32 public aggregatedPublicKey;

    /// @dev Token transfer event
    /// @param sender is  Token sender address, which is the standard Ethereum network account address
    /// @param amount is  Number of token transfers
    /// @param blockNumber is  Block number of the current event
    /// @param targetErc20TokenAddress is  The standard erc20 address that needs to be transferred out is transferred from Ethereum network to dfinity network
    /// @param tokenCanister is Dfinity network target Token address
    /// @param icwallet is The token needs to be transferred to the wallet account of dfinity network
    event Deposit(
        address indexed sender,
        uint256 indexed amount,
        uint256 blockNumber,
        address targetErc20TokenAddress,
        string tokenCanister,
        string icwallet
    );

    struct BridgeAccount {
        uint256 index;
        bool isMember;
    }

    struct TxPool {
        uint256 amount;
        address payable account;
        address erc20Token;
    }

    constructor(address[] memory _member) {
        for (uint256 i = 0; i < _member.length; i++) {
            if (!committee[_member[i]].isMember) {
                committee[_member[i]] = BridgeAccount(committeeNum, true);
                committeeNum++;
            }
        }
    }

    /// @dev Transfer etheum main network token eth, which will flow from etheum to dfinity network through bridge network
    /// @param _tokenCanister is the destination token address of the dfinity network
    /// @param _icwallet is the destination wallet address of the dfinity network
    function depositEth(string memory _tokenCanister, string memory _icwallet)
        public
        payable
    {
        require(msg.value < minAmount, "Too little deposit");
        emit Deposit(
            msg.sender,
            msg.value,
            block.number,
            EthAddress,
            _tokenCanister,
            _icwallet
        );
    }

    /// @dev Transfer the standard erc20 token on Ethereum to the dfinity network
    /// @param _erc20token is Erc20 token address to be transferred
    /// @param _amount is Number of erc20 tokens to be transferred
    /// @param _tokenCanister is the destination token address of the dfinity network
    /// @param _icwallet is the destination wallet address of the dfinity network
    function depositErc20Token(
        IERC20 _erc20token,
        uint256 _amount,
        string memory _tokenCanister,
        string memory _icwallet
    ) public {
        require(_amount < minAmount, "Too little deposit");
        require(assetTable[address(_erc20token)], "Unopened asset Bridge");
        require(
            _erc20token.transferFrom(msg.sender, address(this), _amount),
            "TransferFrom failed"
        );
        emit Deposit(
            msg.sender,
            _amount,
            block.number,
            address(_erc20token),
            _tokenCanister,
            _icwallet
        );
    }

    function getPool(bytes memory _data)
        internal
        pure
        returns (TxPool[] memory)
    {
        TxPool[] memory pool = abi.decode(_data, (TxPool[]));
        return pool;
    }

    ///
    function ReleaseAsset(BridgeLibraryV1.Rollup calldata _rollup) public {
        //require(committee[msg.sender].isMember, "Invalid operator");
        require(aggregatedPublicKey == sha256(_rollup.verifyMultiSign.aggregatedPublicKey),"invalid key");
        bool verif = super.verifyMultisignature(
            _rollup.verifyMultiSign.aggregatedPublicKey,
            _rollup.verifyMultiSign.partPublicKey,
            _rollup.verifyMultiSign.message,
            _rollup.verifyMultiSign.partSignature,
            _rollup.verifyMultiSign.signersBitmask
        );
        require(verif, "Invalid signature");
        TxPool[] memory pool = getPool(_rollup.pool);
        for (uint256 i = 0; i < pool.length; i++) {
            if (pool[i].erc20Token == EthAddress) {
                require(
                    address(this).balance < pool[i].amount,
                    "Insufficient eth tokens"
                );
                pool[i].account.transfer(pool[i].amount);
                continue;
            }
            require(
                assetTable[address(pool[i].erc20Token)],
                "Unopened asset Bridge"
            );
            require(
                Asset.release(
                    IERC20(pool[i].erc20Token),
                    pool[i].account,
                    pool[i].amount
                )
            );
        }
    }

    function addCommittee(address _newMember) public {
        require(!committee[_newMember].isMember, "Already exists");
        committee[_newMember] = BridgeAccount(committeeNum, true);
        committeeNum++;
    }

    function accountLock(address _newMember) public {
        require(
            !accountLockout[_newMember] && committee[_newMember].isMember,
            "Locked"
        );
        accountLockout[_newMember] = true;
        committeeNum--;
    }

    function accountUnlock(address _newMember) public {}

    function addErc20Asset(IERC20 _erc20token) public {
        assetTable[address(_erc20token)] = true;
    }
}
