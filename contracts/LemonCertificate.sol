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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LemonCertificate is ERC721, Ownable {
    uint256 public LEMON_FEE = 0.0003 ether;
    uint256 private _mintedCount = 0;

    // Address to receive the minting fees
    address public DEV_ADDRESS;

    mapping(bytes32 => bool) private _usedPairs;
    mapping(uint48 => uint256) private _certificateToTokenId;
    mapping(uint256 => string) private _base64Metadata;

    constructor(
        address _dev
    ) ERC721("Lemon Learning Path Certificate", "LLPC") Ownable(msg.sender) {
        require(_dev != address(0), "ZeroAddress");
        DEV_ADDRESS = _dev;
    }

    /**
     * @dev Mints an NFT with on-chain metadata.
     * @param _refCode A 3-byte reference code as uint32.
     * @param _id A 6-byte certificate ID as uint48.
     * @param _encodedMetadata The Base64-encoded metadata string.
     */
    function mint(
        uint32 _refCode,
        uint48 _id,
        string memory _encodedMetadata
    ) external payable {
        require(msg.value >= LEMON_FEE, "InvalidFee");

        // Check if the pair was already minted
        bytes32 pairHash = keccak256(abi.encodePacked(_refCode, _id));
        require(!_usedPairs[pairHash], "MintedAlready");

        // Mark pair as used
        _usedPairs[pairHash] = true;

        uint256 tokenId = ++_mintedCount; // We start from 1
        _safeMint(msg.sender, tokenId);

        // Store the off-chain encoded metadata
        _base64Metadata[tokenId] = _encodedMetadata;

        // Link the certificateId to tokenId
        _certificateToTokenId[_id] = tokenId;

        // Transfer fees to DEV_ADDRESS
        (bool success, ) = DEV_ADDRESS.call{value: msg.value}("");
        require(success, "TransferFailed");
    }

    /**
     * @dev Returns the token URI for a given tokenId.
     * Dynamically prepends "data:application/json;base64," to the stored Base64 metadata.
     * @param _id The ID of the token.
     */
    function tokenURI(
        uint256 _id
    ) public view override returns (string memory) {
        require(_ownerOf(_id) != address(0), "InvalidTokenId");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    _base64Metadata[_id]
                )
            );
    }

    //////////////////////////////////////////
    // Dapp Utility Functions
    //////////////////////////////////////////

    /**
     * @dev Retrieves the tokenId linked to a given certificateId.
     */
    function getTokenIdByCertificateId(
        uint48 certId
    ) external view returns (uint256) {
        uint256 tokenId = _certificateToTokenId[certId];
        require(
            tokenId > 0 || _ownerOf(tokenId) != address(0),
            "InvalidTokenId"
        );
        return tokenId;
    }

    //////////////////////////////////////////
    // Access Control Functions
    //////////////////////////////////////////

    function setDevAddress(address _dev) external onlyOwner {
        require(_dev != address(0), "ZeroAddress");
        DEV_ADDRESS = _dev;
    }

    function setMintingFee(uint256 _fee) external onlyOwner {
        require(_fee > 0, "InvalidFee");
        LEMON_FEE = _fee;
    }
}
