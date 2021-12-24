// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract OtterPAW is ERC721, Ownable {
    string private _pawURI;
    bool private _finalized;

    uint256 public currentTokenIndex;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public claimed;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory pawURI_
    ) ERC721(name_, symbol_) {
        _pawURI = pawURI_;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            'ERC721Metadata: URI query for nonexistent token'
        );
        return _pawURI;
    }

    function setWhitelist(address[] memory otters_) external onlyOwner {
        require(otters_.length != 0, 'at least 1 otter');
        for (uint256 i; i < otters_.length; i++) {
            whitelist[otters_[i]] = true;
        }
    }

    function unsetWhitelist(address[] memory otters_) external onlyOwner {
        require(otters_.length != 0, 'at least 1 otter');
        for (uint256 i; i < otters_.length; i++) {
            whitelist[otters_[i]] = false;
        }
    }

    function setURI(string memory uri_) external onlyOwner {
        require(!_finalized, 'can not set URI after finalized');
        _pawURI = uri_;
    }

    function finalize() external onlyOwner {
        require(!_finalized, 'already finalized');
        _finalized = true;
    }

    function claim() external {
        require(msg.sender != address(0), 'zero address');
        require(whitelist[msg.sender], 'not in whitelist');
        require(claimed[msg.sender] == 0, 'already claimed');
        require(
            block.timestamp > 1640350800,
            'party start at 2021-12-24T013:00:00Z'
        );

        currentTokenIndex += 1;
        claimed[msg.sender] = currentTokenIndex;
        _mint(msg.sender, currentTokenIndex);
    }
}
