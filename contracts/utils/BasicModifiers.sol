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

abstract contract BasicModifiers {
    error ZeroValueError();
    error ZeroUserError();
    error ZeroAddressError();

    modifier mustNotBeZero(uint256 _value) {
        if (_value == uint256(0)) revert ZeroValueError();
        _;
    }

    modifier mustBeValidUser(bytes32 _user) {
        if (_user == bytes32(0)) revert ZeroUserError();
        _;
    }

    modifier mustBeValidAddress(address _address) {
        if (_address == address(0)) revert ZeroAddressError();
        _;
    }
}
