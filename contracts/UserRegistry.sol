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

import "./utils/AccessManager.sol";
import "./utils/BasicModifiers.sol";
import "./interfaces/IUserRegistry.sol";

contract UserRegistry is IUserRegistry, AccessManager, BasicModifiers {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_MANAGER, msg.sender);
    }

    mapping(bytes32 => address) private _id_to_address;
    mapping(address => bytes32) private _address_to_id;

    function createOrUpdateUser(
        bytes32 userId,
        address userAddress
    )
        external
        override
        onlyRole(ROLE_MANAGER)
        mustBeValidUser(userId)
        mustBeValidAddress(userAddress)
    {
        require(
            // Check if the address is already associated with the id
            // Or there's no id associated with the address (new user)
            _address_to_id[userAddress] == userId ||
                _address_to_id[userAddress] == bytes32(0),
            "AlreadyUsedAddress"
        );

        address existingAddress = _id_to_address[userId];

        _id_to_address[userId] = userAddress;
        _address_to_id[userAddress] = userId;

        if (existingAddress == address(0)) {
            emit UserCreated(userId, userAddress);
        } else emit UserUpdated(userId, userAddress);
    }

    function deleteUser(
        bytes32 userId
    ) external override onlyRole(ROLE_MANAGER) mustBeValidUser(userId) {
        address userAddress = _id_to_address[userId];

        delete _id_to_address[userId];
        delete _address_to_id[userAddress];

        emit UserDeleted(userId);
    }

    function getAddressOfUser(
        bytes32 userId
    ) external view override returns (address) {
        return _id_to_address[userId];
    }

    function getIdOfUser(
        address userAddress
    ) external view override returns (bytes32) {
        return _address_to_id[userAddress];
    }

    function version() external pure override returns (string memory) {
        return "0.0.1";
    }
}
