pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./state.sol";

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
