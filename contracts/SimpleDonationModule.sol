// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleDonationModule is AccessControl {
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");

    error ValueCantBeZero();
    error UserHasNoDonations();
    error ZeroUserError();

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

    struct User {
        uint256 totalReceived;
        uint256 claimed;
    }

    mapping(bytes32 => User) private registry;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_MANAGER, msg.sender);
    }

    function donate(
        bytes32 userId
    ) public payable mustNotBeZero(msg.value) mustBeValidUser(userId) {
        registry[userId].totalReceived += msg.value;
        emit DonationReceived(msg.sender, userId, msg.value);
    }

    function getUser(bytes32 userId) public view returns (User memory) {
        return registry[userId];
    }

    function claimFor(
        bytes32 userId,
        address destination
    ) public onlyRole(ROLE_MANAGER) mustBeValidUser(userId) {
        require(destination != address(0), "InvalidAddress");

        User storage user = registry[userId];

        if (user.totalReceived == 0) revert UserHasNoDonations();
        if (user.totalReceived == user.claimed) revert UserHasNoDonations();

        uint256 pendingBalance = user.totalReceived - user.claimed;
        user.claimed = user.totalReceived;

        payable(destination).transfer(pendingBalance);
        emit DonationClaimed(destination, userId, pendingBalance);
    }

    // Acces Control functions
    function addManager(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ROLE_MANAGER, _user);
    }

    function revokeManager(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ROLE_MANAGER, _user);
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
}
