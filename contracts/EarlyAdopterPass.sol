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

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract EarlyAdopterPass is ERC721, ERC721Enumerable {
    using Strings for uint256;
    uint256 private _mintedCount = 0;
    uint256 public MAX_SUPPLY = 0;

    mapping(bytes3 => address) private _claimedCodes;
    mapping(address => bool) private _claimedAddresses;

    constructor(
        uint256 _maxSupply,
        address _genesis_holder
    ) ERC721("Lemon Early Adopter NFT", "LEAD") {
        require(_maxSupply > 0, "InvalidSupply");

        if (_genesis_holder != address(0)) {
            _safeMint(_genesis_holder, _mintedCount++);
            _claimedAddresses[_genesis_holder] = true;
        }

        MAX_SUPPLY = _maxSupply;
    }

    //////////////////////////////////////////
    // Utility functions
    //////////////////////////////////////////
    function isClaimedCodeOrAddress(
        bytes3 code,
        address recipient
    ) public view returns (bool) {
        return
            _claimedCodes[code] != address(0) || _claimedAddresses[recipient];
    }

    function recipientOfCode(
        bytes3 code
    ) public view returns (address recipient, uint256 tokenId) {
        recipient = _claimedCodes[code];
        tokenId = recipient == address(0)
            ? 0
            : tokenOfOwnerByIndex(recipient, 0);
    }

    // Portable iplementation of EIP-191 personal_sign from OpenZeppelin's MessageHashUtils.sol
    function _toEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    // Portable iplementation OpenZeppelin's tryRecover from ECDSA.sol
    function _tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            if (
                uint256(s) >
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
            ) {
                return (address(0));
            }

            // If the signature is valid (and not malleable), return the signer address
            /// @dev see https://x.com/ShieldifySec/status/1776166822909509954
            return ecrecover(hash, v, r, s);
        } else {
            return (address(0));
        }
    }

    //////////////////////////////////////////
    // ERC721 and ERC721Enumerable overrides
    //////////////////////////////////////////

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //////////////////////////////////////////
    // Token minting function
    //////////////////////////////////////////

    function safeMint(
        bytes3 code,
        address recipient,
        address authSigner,
        bytes calldata signature
    ) public returns (uint256 tokenId) {
        require(
            recipient != address(0) && authSigner != address(0),
            "AddressZero"
        );
        require(code != bytes3(0), "InvalidCode");
        require(_mintedCount < MAX_SUPPLY, "CapReached");
        require(!isClaimedCodeOrAddress(code, recipient), "AlreadyClaimed");

        // Hash the parameters
        bytes32 hash = _toEthSignedMessageHash(
            keccak256(abi.encodePacked(code, recipient, authSigner))
        );

        require(_tryRecover(hash, signature) == authSigner, "InvalidSignature");
        require(!isClaimedCodeOrAddress(code, authSigner), "AlreadyClaimed");

        tokenId = _mintedCount++;
        _safeMint(recipient, tokenId);

        // Mark the code as claimed for recipient
        _claimedCodes[code] = recipient;

        // Mark the authSigner and recipient as claimed addresses
        /// @dev This is to prevent same addresses claiming multiple times
        _claimedAddresses[recipient] = true;
        _claimedAddresses[authSigner] = true;
    }

    //////////////////////////////////////////
    // NFT Metadata functions
    //////////////////////////////////////////
    function tokenURI(
        uint256 tokenId
    ) public pure override returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Lemon Early Adopter #',
            tokenId.toString(),
            '",',
            '"description": "Lemon Early Adopter Pass is a limited edition NFT that grants access to exclusive features.",',
            '"image": "',
            imageURI(),
            '",',
            '"animation_url": "',
            animationURI(),
            '",',
            '"external_url": "https://lmdt.xyz/claim"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function imageURI() internal pure returns (string memory) {
        return "ipfs://QmYUCntvPtSA4aUTmGp9VdLFUYVVVkUGPeC5uP4zqipSZ4";
    }

    function animationURI() internal pure returns (string memory) {
        return "ipfs://QmRHPbjp7ooBWKU5eLFDSF3Kp3g2x8mRpgbjQqytx7JjkJ";
    }
}
