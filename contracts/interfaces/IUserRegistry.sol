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

interface IUserRegistry {
    event UserCreated(bytes32 indexed userId, address userAddress);
    event UserUpdated(bytes32 indexed userId, address userAddress);
    event UserDeleted(bytes32 indexed userId);

    /**
     * Creates or updates a given user
     * @param userId The id of the user
     * @param userAddress The address of the user
     */
    function createOrUpdateUser(bytes32 userId, address userAddress) external;

    function deleteUser(bytes32 userId) external;

    function getAddressOfUser(bytes32 userId) external view returns (address);

    function getIdOfUser(address userAddress) external view returns (bytes32);

    function version() external pure returns (string memory);
}
