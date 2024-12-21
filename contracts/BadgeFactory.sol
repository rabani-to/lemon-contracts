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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BadgeFactory is Ownable {
    // Address to receive the minting fees
    address public DEV_ADDRESS;

    // Minting Fees
    uint256 public LEMON_FEE = 0.000025 ether;

    constructor(address devAddress) Ownable(msg.sender) {
        require(devAddress != address(0), "BadgeFactory: DEV_ADDRESS");
        DEV_ADDRESS = devAddress;
    }

    // Base IPFS URL to link badges
    string public BASE_IPFS = "https://ipfs.io/ipfs/";

    event CollectionCreated(
        bytes32 indexed collectionId,
        address indexed collectionAddress
    );

    event BadgeMinted(
        bytes3 indexed lemonId,
        address indexed recipient,
        bytes32 collectionId,
        uint256 tokenId
    );

    event BaseIPFSUpdated(string newBaseIPFS);

    // Mapping to store addresses of deployed collections
    mapping(bytes32 => address) private _collections;

    // Some "special" collections might need an extra fee to mint
    mapping(address => uint256) private _collectionFees;

    //////////////////////////////////////////
    // Base Utility Functions
    //////////////////////////////////////////

    function formatCollectionId(
        string calldata name,
        string calldata symbol,
        string calldata ipfsCID
    ) public pure returns (bytes32 collectionId) {
        collectionId = keccak256(abi.encodePacked(name, symbol, ipfsCID));
    }

    function getBaseIPFS() public view returns (string memory) {
        return BASE_IPFS;
    }

    function getCollectionAddress(
        bytes32 collectionId
    ) public view returns (address) {
        return _collections[collectionId];
    }

    //////////////////////////////////////////
    // Fees Management Functions
    //////////////////////////////////////////

    function getCollectionFees(
        bytes32 collectionId
    ) public view returns (uint256) {
        address collection = _collections[collectionId];
        require(collection != address(0), "BadgeFactory: NonExistent");

        return _getCollectionFees(collection);
    }

    function _getCollectionFees(
        address _collectionAddress
    ) private view returns (uint256 total) {
        // Sum up minting fee + collection fee
        total = LEMON_FEE + _collectionFees[_collectionAddress];
    }

    function setCollectionFees(
        address _collection,
        uint256 fees
    ) external onlyOwner {
        _collectionFees[_collection] = fees;
    }

    function setLemonFee(uint256 _fee) external onlyOwner {
        LEMON_FEE = _fee;
    }

    //////////////////////////////////////////
    // Badge Minting functions
    //////////////////////////////////////////

    function mintBadge(
        bytes32 _collectionId,
        address recipient,
        bytes3 lemonId
    ) external payable {
        require(recipient != address(0), "BadgeFactory: ZeroAddress");

        address collection = _collections[_collectionId];
        require(collection != address(0), "BadgeFactory: NonExistent");

        uint256 mintFees = _getCollectionFees(collection);
        require(msg.value >= mintFees, "BadgeFactory: InvalidFees");

        uint256 tokenId = BaseLemonBadge(collection).mint(recipient);

        emit BadgeMinted(lemonId, recipient, _collectionId, tokenId);
    }

    function addCollection(
        string calldata name,
        string calldata symbol,
        string calldata ipfsCID,
        uint256 fees
    ) public onlyOwner {
        bytes32 collectionId = formatCollectionId(name, symbol, ipfsCID);

        require(
            _collections[collectionId] == address(0),
            "BadgeFactory: AlreadyExists"
        );

        BaseLemonBadge newCollection = new BaseLemonBadge(
            address(this),
            name,
            symbol,
            ipfsCID
        );

        address collectionAddress = address(newCollection);
        _collections[collectionId] = collectionAddress;
        _collectionFees[collectionAddress] = fees;

        emit CollectionCreated(collectionId, collectionAddress);
    }

    function addCollectionBatch(
        string[] calldata _collectionNames,
        string[] calldata _symbols,
        string[] calldata _ipfsCIDs,
        uint256[] calldata _fees
    ) public onlyOwner {
        for (uint256 i = 0; i < _collectionNames.length; i++) {
            addCollection(
                _collectionNames[i],
                _symbols[i],
                _ipfsCIDs[i],
                _fees[i]
            );
        }
    }

    //////////////////////////////////////////
    // Management Functions
    //////////////////////////////////////////

    function setBaseIPFS(string memory newBaseIPFS) external onlyOwner {
        BASE_IPFS = newBaseIPFS;
        emit BaseIPFSUpdated(newBaseIPFS);
    }

    function setDevAddress(address _dev) external onlyOwner {
        require(_dev != address(0), "ZeroAddress");
        DEV_ADDRESS = _dev;
    }

    // Claim all fees collected and send to DEV_ADDRESS
    function claimFees() external {
        payable(DEV_ADDRESS).transfer(address(this).balance);
    }
}

contract BaseLemonBadge is ERC721, Ownable {
    // Factory contract
    BadgeFactory public factory;

    uint256 private _mintedCount;
    string private _ipfsCID;

    constructor(
        address _owner, // should be BadgeFactory
        string memory _name,
        string memory _symbol,
        string memory ipfsCID
    ) ERC721(_name, _symbol) Ownable(_owner) {
        _ipfsCID = ipfsCID;

        // Factory deploys this contract and sets itself as owner
        _transferOwnership(_owner);
        factory = BadgeFactory(_owner);
    }

    //////////////////////////////////////////
    // Utilty Functions
    //////////////////////////////////////////

    function getCollectionId() public view returns (bytes32 collectionId) {
        // We call super contract to get the formatted Collection Id
        collectionId = factory.formatCollectionId(name(), symbol(), _ipfsCID);
    }

    //////////////////////////////////////////
    // NFT Minting
    //////////////////////////////////////////

    function mint(
        address recipient
    ) external onlyOwner returns (uint256 tokenId) {
        // We start from 1
        unchecked {
            tokenId = ++_mintedCount;
        }
        _safeMint(recipient, tokenId);
    }

    //////////////////////////////////////////
    // NFT Metadata
    //////////////////////////////////////////

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        address badgeOwner = _ownerOf(tokenId);
        require(badgeOwner != address(0), "InvalidTokenId");

        bytes32 collectionId = getCollectionId();
        string memory imageURI = string(
            abi.encodePacked(factory.getBaseIPFS(), _ipfsCID)
        );

        bytes memory dataURI = abi.encodePacked(
            '{"name":"',
            name(),
            '","description":"This Badge was minted on Lemon Dapp.",',
            '"image":"',
            imageURI,
            '","external_url":"https://lemon.tips/badges/',
            Strings.toHexString(badgeOwner),
            "?id=",
            Strings.toHexString(uint256(collectionId)),
            '","attributes":[{"trait_type":"NFT ID","value":',
            Strings.toString(tokenId),
            '},{"display_type":"date", "trait_type":"Created At","value":"',
            Strings.toString(block.timestamp),
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
