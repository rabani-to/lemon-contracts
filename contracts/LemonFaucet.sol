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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LemonFaucet is ReentrancyGuard {
    uint256 public constant TOKEN_AMOUNT = 40 * 10 ** 6; // 40 Lemon
    uint256 public constant WAIT_TIME = 1 days;

    mapping(address => uint256) private lastRequestTime;

    address public lemon;

    constructor(address _lemon) {
        require(_lemon != address(0), "ZeroAddress");
        lemon = _lemon;
    }

    function claim(address _address) public nonReentrant {
        require(canWithdraw(_address), "Wait24Hours");
        require(
            IERC20(lemon).transfer(_address, TOKEN_AMOUNT),
            "TransferFailed"
        );
        lastRequestTime[_address] = block.timestamp + WAIT_TIME;
    }

    function canWithdraw(address _address) public view returns (bool) {
        if (lastRequestTime[_address] == 0) return true;
        return block.timestamp >= lastRequestTime[_address];
    }

    function getLastRequestTime(
        address _address
    ) external view returns (uint256) {
        return lastRequestTime[_address];
    }
}
