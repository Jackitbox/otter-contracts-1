// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract OtterPAWMintable is ERC721, Ownable {
    string private _pawURI;
    bool public finalized;

    uint256 public currentTokenIndex;
    address public minter;

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

    function setURI(string memory uri_) external onlyOwner {
        require(!finalized, 'can not set URI after finalized');
        _pawURI = uri_;
    }

    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

    function finalize() external onlyOwner {
        require(!finalized, 'already finalized');
        finalized = true;
    }

    function mint(address receipt) external onlyMinter {
        require(receipt != address(0), 'zero address');
        currentTokenIndex += 1;
        _mint(receipt, currentTokenIndex);
    }

    modifier onlyMinter() {
        require(msg.sender == minter, 'OtterPawMintable: only minter can mint');
        _;
    }
}
