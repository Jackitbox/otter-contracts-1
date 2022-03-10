// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import './interfaces/IOtto.sol';
import './libraries/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract Otto is ERC721AUpgradeable, AccessControlUpgradeable, IOtto {
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    uint256 public constant NUM_ATTRIBUTES = 8;

    string private _baseTokenURI;
    OttoInfo[] private infos;

    struct OttoInfo {
        string name;
        string description;
        uint256 birthday;
        uint256 traits;
        uint256 level;
        uint256 experiences;
        uint256 hungerValue;
        uint256 friendship;
        // [STR, DEF, DEX, INT, LUK, CON, CUTE, BRS]
        int16[NUM_ATTRIBUTES] attributes; // can be changed by level up
        int16[NUM_ATTRIBUTES] attributeBonuses; // from traits & wearable
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    modifier onlyOperator() {
        _checkRole(OPERATOR_ROLE, _msgSender());
        _;
    }

    modifier onlyOttoOwner(uint256 tokenId_) {
        require(
            _msgSender() == ownerOf(tokenId_),
            'caller is not the owner of the token'
        );
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), 'zero address');
        _;
    }

    modifier validOttoId(uint256 tokenId_) {
        require(_exists(tokenId_), 'invalid tokenId');
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) public override initializer {
        ERC721AUpgradeable.initialize(
            name_,
            symbol_,
            maxBatchSize_,
            collectionSize_
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function setName(uint256 tokenId_, string memory name_)
        external
        validOttoId(tokenId_)
        onlyOttoOwner(tokenId_)
    {
        infos[tokenId_].name = name_;
    }

    function setDescription(uint256 tokenId_, string memory desc_)
        external
        validOttoId(tokenId_)
        onlyOttoOwner(tokenId_)
    {
        infos[tokenId_].description = desc_;
    }

    function mint(
        address receipt_,
        uint256 quantity_,
        uint256[] memory arrTraits_
    ) external override onlyOperator nonZeroAddress(receipt_) {
        require(arrTraits_.length == quantity_, 'invalid traits length');

        _safeMint(receipt_, quantity_);
        for (uint256 i = 0; i < quantity_; i++) {
            infos.push(
                OttoInfo({
                    name: '',
                    description: '',
                    birthday: 0,
                    traits: arrTraits_[i],
                    level: 1,
                    experiences: 0,
                    hungerValue: 0,
                    friendship: 0,
                    attributes: [int16(0), 0, 0, 0, 0, 0, 0, 0],
                    attributeBonuses: [int16(0), 0, 0, 0, 0, 0, 0, 0]
                })
            );
        }
    }

    function setBaseURI(string calldata baseURI) external onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function get(uint256 tokenId_)
        external
        view
        validOttoId(tokenId_)
        returns (
            string memory name_,
            string memory desc_,
            uint256 birthday_,
            uint256 traits_,
            uint256 level_,
            uint256 experiences_,
            uint256 hungerValue_,
            uint256 friendship_,
            int16[NUM_ATTRIBUTES] memory attributes_,
            int16[NUM_ATTRIBUTES] memory attributeBonuses_
        )
    {
        OttoInfo storage otto = infos[tokenId_];
        name_ = otto.name;
        desc_ = otto.description;
        birthday_ = otto.birthday;
        traits_ = otto.traits;
        level_ = otto.level;
        experiences_ = otto.experiences;
        hungerValue_ = otto.hungerValue;
        friendship_ = otto.friendship;
        attributes_ = otto.attributes;
        attributeBonuses_ = otto.attributeBonuses;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
