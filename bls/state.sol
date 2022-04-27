pragma solidity ^0.8.0;
contract State{
    bool public open = false;

    function change() public {
        open = !open;
    }
}