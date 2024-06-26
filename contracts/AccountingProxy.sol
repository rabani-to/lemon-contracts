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

import {IUserRegistry} from "./interfaces/IUserRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";

contract AccountingProxy is Nonces {
    IUserRegistry public USER_REGISTRY;
    uint8 public constant decimals = 18;
    uint256 constant tokensPerUser = 10 * decimals; // 10 LEMON Points

    event BalanceUpdated(bytes32 indexed user, uint256 value);

    mapping(bytes32 => uint256) private _balances;
    mapping(bytes32 => bool) private _user_executed_first_tx;

    constructor(IUserRegistry _registry) {
        USER_REGISTRY = _registry;
    }

    function getUserBalance(bytes32 userId) public view returns (uint256) {
        if (USER_REGISTRY.getAddressOfUser(userId) == address(0)) {
            // If the user does not exist, the balance will be 0
            return 0;
        }

        if (_user_executed_first_tx[userId]) {
            // If the user has executed a transaction, the balance will be the
            // account's holdings
            return _balances[userId];
        }

        // If the user has not executed a transaction, the balance will be default
        // balance (10 points / user)
        return tokensPerUser;
    }

    function removeBalance(
        bytes32 userId,
        address userAddress,
        uint256 to_remove,
        bytes calldata signature
    ) external {
        require(
            USER_REGISTRY.getAddressOfUser(userId) == userAddress,
            "InvalidUser"
        );

        uint256 currentNonce = _useNonce(userAddress);

        // Hash the parameters
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(userId, userAddress, to_remove, currentNonce)
            )
        );

        require(
            SignatureChecker.isValidSignatureNow(userAddress, hash, signature),
            "InvalidSignature"
        );

        if (to_remove > _balances[userId]) {
            // Set user allocated points to ZERO if more
            // than available balance is being removed

            _balances[userId] = 0;
        } else {
            _balances[userId] -= to_remove;
        }

        if (!_user_executed_first_tx[userId]) {
            _user_executed_first_tx[userId] = true;
        }

        emit BalanceUpdated(userId, _balances[userId]);
    }
}
