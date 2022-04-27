pragma solidity ^0.8.0;
import "./library/BridgeLibraryV1.2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./assets.sol";
import "./governance.sol";

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
