// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./interface/IERC20.sol";
import "./library/BridgeLibrary.sol";
import "./governance.sol";

contract Bridge {
    struct BridgeAccount {
        uint256 index;
        bool isMember;
    }
    uint256 public committeeNum = 0;
    uint256 bridgeBlockNum = 0;
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

    ///
    function mint(BridgeLibrary.Rollup memory _rollup) public {
        require(_rollup.bridgeBlock > bridgeBlockNum, "Invalid bridgeblock");
        require(committee[msg.sender].isMember, "Invalid operator");
        (bool res, string memory info) = addressVerification(_rollup);
        require(res, info);
        bool verif = BridgeLibrary.verificationRollup(_rollup, salt);
        require(verif, "Invalid signature");
        for (uint256 i = 0; i < _rollup.transactions.length; i++) {
            if (_rollup.transactions[i].erc20Token == EthAddress) {
                require(
                    address(this).balance < _rollup.transactions[i].amount,
                    "Insufficient eth tokens"
                );
                _rollup.transactions[i].account.transfer(
                    _rollup.transactions[i].amount
                );
                continue;
            }
            require(
                assetTable[address(_rollup.transactions[i].erc20Token)],
                "Unopened asset Bridge"
            );
            require(
                IERC20(_rollup.transactions[i].erc20Token).transfer(
                    _rollup.transactions[i].account,
                    _rollup.transactions[i].amount
                ),
                "Transfer failed"
            );
        }
        bridgeBlockNum = _rollup.bridgeBlock;
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

    function addressVerification(BridgeLibrary.Rollup memory _rollup)
        internal
        view
        returns (bool, string memory)
    {
        if (_rollup.committeeSigns.length < (committeeNum * 2) / 3 + 1) {
            return (false, "Insufficient number of member approvals");
        }
        bool[] memory blucket = new bool[](committeeNum);

        for (uint256 i = 0; i < _rollup.committeeSigns.length; i++) {
            if (!committee[_rollup.committeeSigns[i].signAddress].isMember) {
                return (false, "Invalid signer");
            }
            if (
                blucket[committee[_rollup.committeeSigns[i].signAddress].index]
            ) {
                return (false, "Duplicate address");
            }

            blucket[
                committee[_rollup.committeeSigns[i].signAddress].index
            ] = true;
        }
        return (true, "");
    }

    function addErc20Asset(IERC20 _erc20token) public {
        assetTable[address(_erc20token)] = true;
    }
}
