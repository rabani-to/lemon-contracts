// SPDX-License-Identifier: MIT
//
//      ___       ___           ___           ___           ___
//     /  /\     /  /\         /  /\         /  /\         /  /\
//    /  /:/    /  /::\       /  /::|       /  /::\       /  /::|
//   /  /:/    /  /:/\:\     /  /:|:|      /  /:/\:\     /  /:|:|
//  /  /:/    /  /::\ \:\   /  /:/|:|__   /  /:/  \:\   /  /:/|:|__
// /__/:/    /__/:/\:\ \:\ /__/:/_|::::\ /__/:/ \__\:\ /__/:/ |:| /\
// \  \:\    \  \:\ \:\_\/ \__\/  /~~/:/ \  \:\ /  /:/ \__\/  |:|/:/
//  \  \:\    \  \:\ \:\         /  /:/   \  \:\  /:/      |  |:/:/
//   \  \:\    \  \:\_\/        /  /:/     \  \:\/:/       |__|::/
//    \  \:\    \  \:\         /__/:/       \  \::/        /__/:/
//     \__\/     \__\/         \__\/         \__\/         \__\/
//
// https://lemon.tips

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessManager is AccessControl {
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    constructor() {
        _grantRole(ROLE_ADMIN, msg.sender);
        _grantRole(ROLE_MANAGER, msg.sender);
    }

    // Acces Control functions
    function addManager(address _user) public onlyRole(ROLE_ADMIN) {
        _grantRole(ROLE_MANAGER, _user);
    }

    function revokeManager(address _user) public onlyRole(ROLE_ADMIN) {
        _revokeRole(ROLE_MANAGER, _user);
    }
}
