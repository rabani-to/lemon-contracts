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
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

    constructor(address _deafult_owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _deafult_owner);
        _grantRole(ROLE_MANAGER, _deafult_owner);
    }

    // Basic Acces Control methods
    function addManager(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ROLE_MANAGER, _user);
    }

    function revokeManager(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ROLE_MANAGER, _user);
    }
}
