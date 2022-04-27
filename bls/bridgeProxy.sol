// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

import "./governance.sol";
contract BridgeProxy is Governance{
    
    constructor(address _logic, bytes memory _data)   {
           
    }

    // modifier owner() {
    //     require(msg.sender == super._getAdmin(),"Invalid operator");
    //     _;
    // }
    // function upgradeTo(address newImplementation) public owner(){
    //     super._upgradeTo(newImplementation);
    // }
}