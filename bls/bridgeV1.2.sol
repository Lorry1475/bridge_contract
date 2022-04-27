pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract State {
    bool public open = false;

    function change() public {
        open = !open;
    }
}

contract Asset is State {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) public balanceOf;

    modifier stateCheck() {
        require(State.open, "");
        _;
    }

    function transfer(
        IERC20 _erc20,
        address _to,
        uint256 _amount
    ) public stateCheck {
        uint256 balance = balanceOf[msg.sender][address(_erc20)];
        require(balance >= _amount, "");
        balanceOf[msg.sender][address(_erc20)] = balance.sub(_amount);
        balanceOf[_to][address(_erc20)] = balanceOf[_to][address(_erc20)].add(
            _amount
        );
    }

    function release(
        IERC20 _erc20,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        uint256 balance = balanceOf[address(this)][address(_erc20)];
        if (balance < _amount) {
            return false;
        }
        balanceOf[address(this)][address(_erc20)] = balance.sub(_amount);
        balanceOf[_to][address(_erc20)] = balanceOf[_to][address(_erc20)].add(
            _amount
        );
        return true;
    }

    function withdraw(IERC20 _erc20, uint256 _amount) public stateCheck {
        uint256 balance = balanceOf[msg.sender][address(_erc20)];
        require(balance >= _amount, "");
        _erc20.transfer(msg.sender, _amount);
        balanceOf[msg.sender][address(_erc20)] = balance.sub(_amount);
    }

    function addLiquidity(
        IERC20 _erc20,
        uint256 _amount
    ) public {
        _erc20.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender][address(_erc20)] = balanceOf[msg.sender][
            address(_erc20)
        ].add(_amount);
        balanceOf[address(this)][address(_erc20)] = balanceOf[address(this)][
            address(_erc20)
        ].add(_amount);
    }
}


// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)
//0xb4765b4a30875CDea512D356c38e5804C12C7F64
contract Governance {

    // The members of the committee are legal nodes of the bridge network and will undertake the task of cross chain network transfer
    mapping(address => uint256) public committee;
    uint256 public members = 0;
    
    function addMember(address _newmember) internal {
        require(committee[_newmember] == 0,"");
        members++;
        committee[_newmember] = members;
    }

    function subMember(address _newmember) internal {
        require(committee[_newmember] > 0,"");
        committee[_newmember] = 0;
        members--;
    }
}

contract Sequencer is Asset, Governance {
    address public EthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) public assetTable;
    uint256 public challengingPeriod = 30;
    Propose[] private Inbox;
    struct Propose {
        address promoter;
        address[] seconder;
        bool excuted;
        bool revoke;
        bytes transactions;
    }
    event ProposeEvent(uint256 indexed proposeId);

    function Mock() public {
        //     struct Transaction {
        //     uint256 amount;
        //     address payable account;
        //     address erc20Token;
        // }

        // struct VerifyMultiSign {
        //     bytes aggregatedPublicKey;
        //     bytes partPublicKey;
        //     bytes message;
        //     bytes partSignature;
        //     uint256 signersBitmask;
        // }
        // struct Rollup {
        //     uint256 bridgeBlock;
        //     bytes transactions;
        //     VerifyMultiSign verifyMultiSign;
        // }
        // uint256 _bridgeBlock = 0;
        // bytes memory _transactions = hex"ab";
        // BridgeLibrary.VerifyMultiSign memory _verifyMultiSign = BridgeLibrary
        //     .VerifyMultiSign(hex"ab", hex"ab", hex"ab", hex"ab", 0);

        //  BridgeLibrary.Rollup memory _rollup =  BridgeLibrary.Rollup(
        //      _bridgeBlock,_transactions,_verifyMultiSign
        //  );

        //propose(_rollup);
    }

    function getPropose(uint256 _proposed)
        public
        view
        returns (Propose memory)
    {
        require(_proposed < Inbox.length);
        return Inbox[_proposed];
    }

    function getProposeTotal() public view returns (uint256) {
        return Inbox.length;
    }

    function propose(bytes memory  _newblock)
        internal
        returns (uint256 _proposeId)
    {
        address[] memory _seconder = new address[](1);
        _seconder[0] = msg.sender;
   
        // Propose memory  _propose = Propose(
        //     msg.sender,
        //     _seconder,
        //     false,
        //     false,
        //     _newblock

        Inbox.push(Propose(
            msg.sender,
            _seconder,
            false,
            false,
            _newblock
        ));
        _proposeId = Inbox.length - 1;
        emit ProposeEvent(_proposeId);
    }

    function revoke(uint256 _proposed) public {
        require(
            _proposed < Inbox.length &&
                !Inbox[_proposed].excuted &&
                Inbox[_proposed].promoter == msg.sender,
            ""
        );
        Inbox[_proposed].revoke = true;
    }

    function agreement(uint256 _proposed) public {
        require(
            _proposed < Inbox.length &&
                !Inbox[_proposed].excuted &&
                !Inbox[_proposed].revoke,
            ""
        );
        for (uint256 i = 0; i < Inbox[_proposed].seconder.length; i++) {
            if (Inbox[_proposed].seconder[i] == msg.sender) {
                revert();
            }
        }
        Inbox[_proposed].seconder.push(msg.sender);
        // if (Inbox[_proposed].seconder.length >= minimum()) {
        //     excute(Inbox[_proposed]);
        // }
    }

    function excute(uint256 _proposeId) internal {
        Propose storage _proposed = findProposals(_proposeId);
         BridgeLibrary.Transaction[] memory _transactions = BridgeLibrary.decodeTransactions(_proposed.transactions);
        for (uint256 i = 0; i < _transactions.length; i++) {
            if (_transactions[i].erc20Token == EthAddress) {
                require(
                    address(this).balance <
                        _transactions[i].amount,
                    "Insufficient eth tokens"
                );
                _transactions[i].account.transfer(
                    _transactions[i].amount
                );
                continue;
            }
            require(
                assetTable[address(_transactions[i].erc20Token)],
                "Unopened asset Bridge"
            );
            require(
                Asset.release(
                    IERC20(_transactions[i].erc20Token),
                    _transactions[i].account,
                   _transactions[i].amount
                )
            );
        }
        _proposed.excuted = true;
    }

    function findProposals(uint256 _proposeId)
        internal
        view
        returns (Propose storage)
    {
        require(_proposeId < Inbox.length && !Inbox[_proposeId].excuted, "not found proposerId");
        return Inbox[_proposeId];
    }

    function minimum() public view returns (uint256) {
        return (members * 2) / 3 + 1;
    }
}


// import "./assets.sol";
// import "./BlsSignature.sol";
contract BridgeV12 is Sequencer{
    uint256 public committeeNum = 0;
    bool private init;
    // address public EthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Minimum token transfer quantity
    uint256 minAmount = 100000000000000;
    bytes private salt = "v1.0";
    /// @dev Members of the Governance Committee,
    /// who will undertake the token transfer verification between two different networks, dfinity and Ethereum
    //mapping(address => BridgeAccount) public committee;
    mapping(address => bool) public accountLockout;
    // mapping(address => bool) public assetTable;


    mapping(address => uint256) public accountNonce;




    /// @dev Token transfer event
    /// @param from is  Token sender address, which is the standard Ethereum network account address
    /// @param amount is  Number of token transfers
    /// @param blockNumber is  Block number of the current event
    /// @param fromAsset is  The standard erc20 address that needs to be transferred out is transferred from Ethereum network to dfinity network
    /// @param toAsset is Dfinity network target Token address
    /// @param to is The token needs to be transferred to the wallet account of dfinity network
    event Deposit(
        address indexed from,
        uint256 indexed amount,
        uint256 nonce,
        uint256 blockNumber,
        address fromAsset,
        string toAsset,
        string to
    );


    // struct TxPool {
    //     uint256 amount;
    //     address payable account;
    //     address erc20Token;
    // }
    constructor(address[] memory _member) {
        for (uint256 i = 0; i < _member.length; i++) {
            if (committee[_member[i]]==0) {
                addMember(_member[i]);
                // committee[_member[i]] = BridgeAccount(committeeNum, true);
                // committeeNum++;
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
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            msg.value,
            nonce,
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
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            _amount,
            nonce,
            block.number,
            address(_erc20token),
            _tokenCanister,
            _icwallet
        );
    }

    // function getPool(bytes memory _data)
    //     internal
    //     pure
    //     returns (TxPool[] memory)
    // {
    //     TxPool[] memory pool = abi.decode(_data, (TxPool[]));
    //     return pool;
    // }

    function mint(BridgeLibrary.Rollup memory _rollup) public{
        require(committee[msg.sender]>0, "Invalid operator");
        (bool res, string memory info) = addressVerification(_rollup);
        require(res, info);                                                                                                                 
        bool verif = BridgeLibrary.verificationRollup(_rollup, salt);
        require(verif, "Invalid signature");
         BridgeLibrary.Block memory _block =  BridgeLibrary.decodeBlock(_rollup.block);
       
         propose( _block.transactions);
        if (_block.proposeId > 0){
         excute(_block.proposeId);
        }

        // TxPool[] memory pool = getPool(_rollup.pool);
        // for (uint256 i = 0; i < pool.length; i++) {
        //     if (pool[i].erc20Token == EthAddress) {
        //         require(
        //             address(this).balance < pool[i].amount,
        //             "Insufficient eth tokens"
        //         );
        //         pool[i].account.transfer(pool[i].amount);
        //         continue;
        //     }
        //     require(
        //         assetTable[address(pool[i].erc20Token)],
        //         "Unopened asset Bridge"
        //     );
        //     require(
        //         Asset.release(
        //             IERC20(pool[i].erc20Token),
        //             pool[i].account,
        //             pool[i].amount
        //         )
        //     );
        // }
    }

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

    function accountUnlock(address _newMember) public {}

    function addressVerification(BridgeLibrary.Rollup memory _rollup)
        internal
        view
        returns (bool, string memory)
    {
        if (_rollup.committeeSigns.length < minimum()) {
            return (false, "Insufficient number of member approvals");
        }
        bool[] memory blucket = new bool[](members);

        for (uint256 i = 0; i < _rollup.committeeSigns.length; i++) {
            if (committee[_rollup.committeeSigns[i].signAddress] == 0) {
                return (false, "Invalid signer");
            }
            if (
                blucket[committee[_rollup.committeeSigns[i].signAddress]-1]
            ) {
                return (false, "Duplicate address");
            }

            // blucket[
            //     committee[_rollup.committeeSigns[i].signAddress].index
            // ] = true;
        }
        return (true, "");
    }

    function addErc20Asset(IERC20 _erc20token) public {
        assetTable[address(_erc20token)] = true;
    }

    function increaseNonce(address account  ) internal returns(uint256){
        accountNonce[account] = accountNonce[account] + 1;
          return accountNonce[account];
    }

    function getAccountNonce(address account ) public view returns(uint256){
        return accountNonce[account];
    }
}