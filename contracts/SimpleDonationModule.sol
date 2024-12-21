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
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./utils/AccessManager.sol";

contract SimpleDonationModule is AccessManager {
    error ValueCantBeZero();
    error UserHasNoDonations();
    error ClaimingError();
    error ZeroUserError();
    error ZeroAddressError();
    error AddressMismatch();

    event DonationReceived(
        address indexed from,
        bytes32 indexed user,
        uint256 value
    );
    event DonationClaimed(
        address indexed destination,
        bytes32 indexed user,
        uint256 value
    );
    event ETHReceived(address sender, uint256);

    struct User {
        uint256 totalReceived;
        uint256 claimed;
    }

    mapping(bytes32 => bool) claimedBalances;
    mapping(bytes32 => User) private registry;

    constructor() AccessManager(msg.sender) {}

    function donate(
        bytes32 userId
    ) public payable mustNotBeZero(msg.value) mustBeValidUser(userId) {
        registry[userId].totalReceived += msg.value;

        emit DonationReceived(msg.sender, userId, msg.value);
    }

    function getUser(bytes32 userId) public view returns (User memory) {
        return registry[userId];
    }

    function unsafeClaimAll(
        address destination
    ) external onlyRole(ROLE_MANAGER) {
        // NOTE: This should be removed or disabled in production
        // As it allows MANAGERS to claim all the funds in the contract
        payable(destination).transfer(address(this).balance);
    }

    function claimFor(
        bytes32 userId,
        address destination,
        bytes calldata stateHash
    )
        public
        onlyRole(ROLE_MANAGER)
        mustBeValidUser(userId)
        mustBeValidAddress(destination)
    {
        bytes32 claimHash = MessageHashUtils.toEthSignedMessageHash(stateHash);
        if (claimedBalances[claimHash]) revert ClaimingError();

        _claimFor(userId, claimHash, destination);
    }

    function _claimFor(
        bytes32 userId,
        bytes32 claimHash,
        address destination
    ) private mustBeValidUser(userId) mustBeValidAddress(destination) {
        User storage user = registry[userId];

        uint256 balance = user.totalReceived - user.claimed;

        // Try to transfer the balance to the destination address
        if (balance == 0) revert UserHasNoDonations();
        payable(destination).transfer(balance);

        // Update the user's claimed balance
        user.claimed = user.totalReceived;

        // Mark the claim as completed
        claimedBalances[claimHash] = true;

        // Increment the total transactions counter
        emit DonationClaimed(destination, userId, balance);
    }

    // Acces Control functions

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    // Modifiers
    modifier mustNotBeZero(uint256 value) {
        if (value == 0) revert ValueCantBeZero();
        _;
    }

    modifier mustBeValidUser(bytes32 userId) {
        if (userId == bytes32(0)) revert ZeroUserError();
        _;
    }

    modifier mustBeValidAddress(address addy) {
        if (addy == address(0)) revert ZeroAddressError();
        _;
    }
}
