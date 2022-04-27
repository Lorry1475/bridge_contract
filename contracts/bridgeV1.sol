// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./interface/IERC20.sol";
import "./interface/IUniswap.sol";
import "./library/BridgeLibraryV1.sol";

contract BridgeV1 {
    uint256 public molecule = 1;
    uint256 public denominator = 1000;
    bool isInit = false;
    bool lock = false;
    uint256 public committeeNum = 0;
    address public EthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address owner;
    /// @dev Minimum token transfer quantity
    uint256 minAmount = 1;
    bytes private salt = "v1.0";
    /// @dev Members of the Governance Committee,
    /// who will undertake the token transfer verification between two different networks, dfinity and Ethereum
    mapping(address => BridgeAccount) public committee;
    mapping(address => address) public uniswapPair;
    mapping(address => IUniswapV2.Pair) public uniswapTokens;
    mapping(address => bool) public accountLockout;
    // mapping(address => bool) public assetTable;
    mapping(address => uint256) public account;
    mapping(address => mapping(uint256 => Asset)) public assetPipeline;
    mapping(address => uint256) public accountNonce;
    mapping(uint256 => bool) public network;

    /// @dev Token transfer event
    /// @param from is  Token sender address, which is the standard Ethereum network account address
    /// @param amount is  Number of token transfers
    /// @param networkid network
    /// @param nonce is accout nonce
    /// @param blockNumber is  Block number of the current event
    /// @param fromAsset is  The standard erc20 address that needs to be transferred out is transferred from Ethereum network to dfinity network
    /// @param toAsset is Dfinity network target Token address
    /// @param to is The token needs to be transferred to the wallet account of dfinity network
    event Deposit(
        address from,
        uint256 amount,
        uint256 networkid,
        uint256 nonce,
        uint256 blockNumber,
        address fromAsset,
        string toAsset,
        string to
    );

    struct BridgeAccount {
        uint256 index;
        bool isMember;
    }

    struct Asset {
        string token;
        string symbol;
        uint256 decimal;
        bool exist;
    }

    modifier Sender() {
        require(
            !BridgeLibraryV1.isContract(msg.sender),
            "Contract not supported"
        );
        _;
    }

    modifier Lock() {
        require(!lock, "locking");
        lock = true;
        _;
        lock = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function addNetWork(uint256 networkid) public {
        network[networkid] = true;
    }

    function addAsset(
        uint256 networkid,
        address erc20,
        Asset memory asset
    ) public {
        require(
            network[networkid],
            "The network does not support asset transfer"
        );
        assetPipeline[erc20][networkid] = asset;
    }

    /// @dev Transfer etheum main network token eth, which will flow from etheum to dfinity network through bridge network
    /// @param wallet is the destination wallet address of the other network
    function depositEth(uint256 networkid, string memory wallet)
        public
        payable
        Sender
    {
        require(
            assetPipeline[EthAddress][networkid].exist,
            "No longer on balance sheet"
        );
        uint256 fee = getFee(msg.value);
        require(fee > 0, "fee not enough");
        uint256 surplus = msg.value - fee;
        require(msg.value > minAmount, "Too little deposit");
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            surplus,
            networkid,
            nonce,
            block.number,
            EthAddress,
            assetPipeline[EthAddress][networkid].token,
            wallet
        );
    }

    /// @dev Transfer the standard erc20 token on Ethereum to the dfinity network
    /// @param _erc20token is Erc20 token address to be transferred
    /// @param _amount is Number of erc20 tokens to be transferred
    /// @param wallet is the destination wallet address of the other network
    function depositErc20Token(
        IERC20 _erc20token,
        uint256 networkid,
        uint256 _amount,
        string memory wallet
    ) public Sender {
        require(
            assetPipeline[address(_erc20token)][networkid].exist,
            "No longer on balance sheet"
        );

        uint256 fee = getFee(_amount);
        require(fee > 0, "fee not enough");
        uint256 surplus = _amount - fee;

        require(
            _erc20token.transferFrom(msg.sender, address(this), _amount),
            "TransferFrom failed"
        );
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            surplus,
            networkid,
            nonce,
            block.number,
            address(_erc20token),
            assetPipeline[address(_erc20token)][networkid].token,
            wallet
        );
    }

    function increaseNonce(address account) internal returns (uint256) {
        accountNonce[account] = accountNonce[account] + 1;
        return accountNonce[account];
    }

    function getAccountNonce(address account) public view returns (uint256) {
        return accountNonce[account];
    }

    // function getPool(bytes memory _data)
    //     internal
    //     pure
    //     returns (TxPool[] memory)
    // {
    //     TxPool[] memory pool = abi.decode(_data, (TxPool[]));
    //     return pool;
    // }

    // function mint(BridgeLibraryV1.Rollup memory _rollup) public Lock {
    //     require(committee[msg.sender].isMember, "Invalid operator");
    //     (bool res, string memory info) = addressVerification(_rollup);
    //     require(res, info);
    //     bool verif = BridgeLibraryV1.verificationRollup(_rollup, salt);
    //     require(verif, "Invalid signature");
    //     TxPool[] memory pool = getPool(_rollup.pool);
    //     for (uint256 i = 0; i < pool.length; i++) {
    //         if (pool[i].erc20Token == EthAddress) {
    //             require(
    //                 address(this).balance < pool[i].amount,
    //                 "Insufficient eth tokens"
    //             );
    //             pool[i].account.transfer(pool[i].amount);
    //             continue;
    //         }
    //         require(
    //             assetTable[address(pool[i].erc20Token)],
    //             "Unopened asset Bridge"
    //         );
    //         require(
    //             IERC20(pool[i].erc20Token).transfer(
    //                 pool[i].account,
    //                 pool[i].amount
    //             ),
    //             "Transfer failed"
    //         );
    //     }
    // }

    // function addCommittee(address _newMember) public {
    //     require(!committee[_newMember].isMember, "Already exists");
    //     committee[_newMember] = BridgeAccount(committeeNum, true);
    //     committeeNum++;
    // }

    // function accountLock(address _newMember) public {
    //     require(
    //         !accountLockout[_newMember] && committee[_newMember].isMember,
    //         "Locked"
    //     );
    //     accountLockout[_newMember] = true;
    //     committeeNum--;
    // }

    // function accountUnlock(address _newMember) public {}

    // function addressVerification(BridgeLibraryV1.Rollup memory _rollup)
    //     internal
    //     view
    //     returns (bool, string memory)
    // {
    //     if (_rollup.committeeSigns.length < (committeeNum * 2) / 3 + 1) {
    //         return (false, "Insufficient number of member approvals");
    //     }
    //     bool[] memory blucket = new bool[](committeeNum);

    //     for (uint256 i = 0; i < _rollup.committeeSigns.length; i++) {
    //         if (!committee[_rollup.committeeSigns[i].signAddress].isMember) {
    //             return (false, "Invalid signer");
    //         }
    //         if (
    //             blucket[committee[_rollup.committeeSigns[i].signAddress].index]
    //         ) {
    //             return (false, "Duplicate address");
    //         }

    //         blucket[
    //             committee[_rollup.committeeSigns[i].signAddress].index
    //         ] = true;
    //     }
    //     return (true, "");
    // }

    function getFee(uint256 value) public view returns (uint256) {
        return (value * molecule) / denominator;
    }
}
