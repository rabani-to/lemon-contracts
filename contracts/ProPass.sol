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

import "./utils/AccessManager.sol";

enum TierLevels {
    TIER_1,
    TIER_2,
    TIER_3
}

contract ProPass is ERC721, ERC721Enumerable, AccessManager {
    //////////////////////////////////////////
    // Constants / Tier Prices
    //////////////////////////////////////////

    // Utility fixed parts for the NFT
    string private constant BASE_SVG_START =
        "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1080' height='1080' fill='none'%3E%3Cpath fill='%23";
    string private constant BASE_SVG_MIDDLE =
        "' d='M0 0h1080v1080H0z'/%3E%3Crect width='947' height='297' x='66' y='712' fill='%23000' rx='54'/%3E%3Crect width='959' height='309' x='60' y='706' stroke='%23000' stroke-opacity='.2' stroke-width='12' rx='60'/%3E%3Ctext xml:space='preserve' fill='%23fff' font-family='Monaco,Consolas,Helvetica,Arial,monospace' font-size='72' letter-spacing='-0.035em'%3E%3Ctspan x='109' y='818'%3EVALID FOR: ";
    string private constant BASE_SVG_FINAL =
        "%3C/tspan%3E%3C/text%3E%3Cpath fill='%23000' fill-rule='evenodd' d='m68 109-2-7V73l1-3v-2l2-2 2-1h3l5 2 2 5v24h11l2 1 1 1a18 18 0 0 1 1 5l-1 6-4 2-18 1c-2 0-3 0-5-2v-1m63-24 5 1 1 4-1 6-6 1h-10l-1 4h15l5 1 2 4-2 5-6 1h-22l-5-2-2-8V74c0-5 2-8 7-8h22l6 1 2 4-2 5-5 1h-15v8h12Zm33 2c3 3 10 15 14 15l4-2 8-10v16l2 5 6 1 5-1 1-6V76l-2-8c-10-10-20 7-25 12-5-5-20-23-27-10l-1 6v29c0 5 3 7 8 7l5-2 2-5V87Zm68-22c-24-1-29 47 0 47 30 0 25-46 0-47Zm10 29-3 5-2 1a16 16 0 0 0-2 2h-1l-2 1-2-1-1-1-1-1-3-2-2-3a14 14 0 0 1-1-6v-1a14 14 0 0 1 6-10l1-1 1-1h4v1c3 1 4 3 6 5l2 6v6m62 11-2 5-8 2-2-1-17-11v6l-1 4-8 2-4-1-2-5V73l2-6 6-2 4 1 4 3 12 17 5-15 1-4 4-2 4 2 2 4v34Z' clip-rule='evenodd'/%3E%3Cpath fill='%23000' d='M623 194c30-33 68-57 110-70 15-5 31-8 47-11a353 353 0 0 0 48-14c8-4 17-7 26-9 12-2 25-1 35 5 19 10 27 26 35 43l1 1a162 162 0 0 0 24 39l3 5a246 246 0 0 1 61 149c3 43-15 103-34 138l-3 8a306 306 0 0 1-213 151h-1l-13 1-10 2-5 1-6 3c-4 4-9 6-14 7h-15l-45-15a26 26 0 0 1-19-15l-2-5-1-5-1-4-3-6c-34-41-58-88-71-138a278 278 0 0 1 12-173c13-32 31-62 54-88Z'/%3E%3C/svg%3E";

    uint256 private constant TIER_1_DURATION = 30 days; // 1 month
    uint256 private constant TIER_2_DURATION = 6 * 30 days; // 6 months
    uint256 private constant TIER_3_DURATION = 15 * 365 days; // 15 years

    uint256 public TIER_1_PRICE = 0.002 ether;
    uint256 public TIER_2_PRICE = 0.01 ether;
    uint256 public TIER_3_PRICE = 0.1 ether;

    address public FEE_RECEIVER;

    using Strings for uint256;

    // Struct to store NFT pass data, creation time and tier level
    struct PassData {
        uint256 created_at;
        TierLevels tier;
    }

    mapping(uint256 => PassData) private _passData;
    uint256 private _mintedCount = 0;

    constructor(
        address _feeReceiver
    ) ERC721("Lemon Pro Pass", "BPASS") AccessManager(msg.sender) {
        require(_feeReceiver != address(0), "InvalidFeeReceiver");

        FEE_RECEIVER = _feeReceiver;
    }

    //////////////////////////////////////////
    // Price config and Interface overrides
    //////////////////////////////////////////

    function getTierPrices(TierLevels tier) public view returns (uint256) {
        if (tier == TierLevels.TIER_1) return TIER_1_PRICE;
        if (tier == TierLevels.TIER_2) return TIER_2_PRICE;
        if (tier == TierLevels.TIER_3) return TIER_3_PRICE;

        revert("InvalidTier");
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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

    //////////////////////////////////////////
    // Minting implementation for each tier
    //////////////////////////////////////////

    function buyTier1(address recipient) public payable {
        require(msg.value >= TIER_1_PRICE, "InsufficientFunds");
        _mintPass(recipient, TierLevels.TIER_1);
    }

    function buyTier2(address recipient) public payable {
        require(msg.value >= TIER_2_PRICE, "InsufficientFunds");
        _mintPass(recipient, TierLevels.TIER_2);
    }

    function buyTier3(address recipient) public payable {
        require(msg.value >= TIER_3_PRICE, "InsufficientFunds");
        _mintPass(recipient, TierLevels.TIER_3);
    }

    function selfMint(
        address recipient,
        TierLevels tier
    ) public onlyRole(ROLE_MINTER) {
        _mintPass(recipient, tier);
    }

    //////////////////////////////////////////
    // Private safe minting function
    //////////////////////////////////////////

    function _mintPass(address recipient, TierLevels tier) private {
        require(recipient != address(0), "InvalidRecipient");

        if (msg.value > 0) {
            (bool success, ) = FEE_RECEIVER.call{value: msg.value}("");
            require(success, "TransferFailed");
        }

        uint256 tokenId = _mintedCount++;
        _safeMint(recipient, tokenId);

        _passData[tokenId] = PassData({
            created_at: block.timestamp,
            tier: tier
        });
    }

    //////////////////////////////////////////
    // ERC721 Metadata overrides
    //////////////////////////////////////////

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        (
            TierLevels tier,
            ,
            uint256 expiration_time,
            ,
            string memory imageURL
        ) = getPassData(tokenId);

        bytes memory dataURI = abi.encodePacked(
            '{"name":"Lemon Pro Pass #',
            tokenId.toString(),
            '","description":"Lemon Pro Pass is a subscription service that unlocks premium features on Lemon Dapp.",',
            '"image":"',
            imageURL,
            '","external_url":"https://beta.lemon.tips/pro",',
            '"attributes":[{"trait_type":"Level","value":',
            uint256(tier).toString(),
            '},{"display_type":"date","trait_type":"Expiration","value":',
            expiration_time.toString(),
            "}]}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    //////////////////////////////////////////
    // NFT Utility functions
    //////////////////////////////////////////

    // Get pass data for a specific token ID
    // Returns tier, created_at, expiration_time, pending_time, imageURL
    /// @dev pending_time is the time (in seconds) left until the pass expires
    function getPassData(
        uint256 _id
    )
        public
        view
        returns (
            TierLevels tier,
            uint256 created_at,
            uint256 expiration_time,
            uint256 pending_time,
            string memory imageURL
        )
    {
        PassData memory data = _passData[_id];

        tier = data.tier;
        created_at = data.created_at;
        (pending_time, expiration_time) = getPendingTime(
            tier,
            created_at,
            block.timestamp
        );

        imageURL = getSVGContent(_id, pending_time);
    }

    function getPendingTime(
        TierLevels tier,
        uint256 created_at,
        uint256 block_timestamp
    ) internal pure returns (uint256 pending_time, uint256 expiration_time) {
        pending_time = 0;
        uint256 duration = 0;

        uint256 currentTime = block_timestamp;

        if (tier == TierLevels.TIER_1) duration = TIER_1_DURATION;
        else if (tier == TierLevels.TIER_2) duration = TIER_2_DURATION;
        else if (tier == TierLevels.TIER_3) duration = TIER_3_DURATION;
        else revert("InvalidTier");

        expiration_time = created_at + duration;

        if (expiration_time > currentTime) {
            pending_time = expiration_time - currentTime;
        }
    }

    function getSVGContent(
        uint256 _id,
        uint256 pendingTime
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    BASE_SVG_START,
                    pendingTime < 1 days ? "FF3333" : pendingTime < 5 days
                        ? "FF7110"
                        : "00FF38",
                    BASE_SVG_MIDDLE,
                    pendingTime.toString(),
                    "%3C/tspan%3E%3Ctspan x='109' y='939'%3ETKN %23",
                    _id.toString(),
                    BASE_SVG_FINAL
                )
            );
    }

    //////////////////////////////////////////
    // Private management functions
    //////////////////////////////////////////

    function setTierPrices(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3
    ) public onlyRole(ROLE_MANAGER) {
        if (tier1 > 0) TIER_1_PRICE = tier1;
        if (tier2 > 0) TIER_2_PRICE = tier2;
        if (tier3 > 0) TIER_3_PRICE = tier3;
    }

    function setFeeReceiver(address feeReceiver) public onlyRole(ROLE_MANAGER) {
        require(feeReceiver != address(0), "InvalidFeeReceiver");
        FEE_RECEIVER = feeReceiver;
    }

    //////////////////////////////////////////
    // Fallback function to prevent direct transfers
    //////////////////////////////////////////
    receive() external payable {
        revert("NO_DIRECT_TRANSFERS");
    }
}
