// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)
//0xb4765b4a30875CDea512D356c38e5804C12C7F64
pragma solidity ^0.8.0;

contract Governance  {

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