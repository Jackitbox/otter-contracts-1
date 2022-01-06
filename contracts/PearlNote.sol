// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './interfaces/IPearlNote.sol';
import './interfaces/IERC20.sol';
import './interfaces/IOtterLake.sol';

import './types/Ownable.sol';

interface IOtterPAWMintable {
    function mint(address receipt) external;
}

contract PearlNote is IPearlNote, ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    struct LockInfo {
        uint256 amount;
        uint256 endEpoch;
    }

    IERC20 public immutable pearl;
    IOtterLake public immutable lake;
    bool public unlockedAll;
    IOtterPAWMintable public paw;

    // token id => lock info
    mapping(uint256 => LockInfo) public lockInfos;
    Counters.Counter private _tokenIdTracker;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address _pearl,
        address _lake
    ) ERC721(name, symbol) {
        unlockedAll = false;

        _setBaseURI(baseURI);

        require(_pearl != address(0));
        pearl = IERC20(_pearl);
        require(_lake != address(0));
        lake = IOtterLake(_lake);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'PearlNote: URI query for nonexistent token');
        return
            string(
                abi.encodePacked(
                    super.baseURI(),
                    toString(address(this)),
                    '/',
                    tokenId.toString()
                )
            );
    }

    function lockAmount(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return lockInfos[tokenId].amount;
    }

    function endEpoch(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return lockInfos[tokenId].endEpoch;
    }

    function setPaw(address paw_) external onlyOwner {
        paw = IOtterPAWMintable(paw_);
    }

    function mint(
        address _user,
        uint256 _amount,
        uint256 _endEpoch
    ) external override onlyLake returns (uint256) {
        require(_amount > 0, "PearlNote: can't mint with 0 amount");
        pearl.transferFrom(msg.sender, address(this), _amount);

        uint256 tokenId = _tokenIdTracker.current();

        lockInfos[tokenId] = LockInfo({amount: _amount, endEpoch: _endEpoch});

        _safeMint(_user, _tokenIdTracker.current());
        _tokenIdTracker.increment();

        return tokenId;
    }

    /// @dev Burn the NFT and get token locked inside back
    /// @param tokenId the token id which got burned
    /// @return the amount of unlocked token
    function burn(uint256 tokenId)
        external
        override
        onlyLake
        returns (uint256)
    {
        LockInfo memory lockInfo = lockInfos[tokenId];
        if (!unlockedAll) {
            require(
                lockInfo.endEpoch <= lake.epoch(),
                'PearlNote: the note is not expired'
            );
        }
        address owner = ownerOf(tokenId);
        pearl.transfer(owner, lockInfo.amount);
        _burn(tokenId);
        if (address(paw) != address(0)) {
            paw.mint(owner);
        }
        delete lockInfos[tokenId];
        return lockInfo.amount;
    }

    function extendLock(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _endEpoch
    ) external override onlyLake {
        LockInfo storage lockInfo = lockInfos[_tokenId];
        pearl.transferFrom(msg.sender, address(this), _amount);
        lockInfo.amount = lockInfo.amount.add(_amount);
        lockInfo.endEpoch = _endEpoch;
    }

    /// @dev Emgerency use
    function unlockAll() external onlyOwner {
        unlockedAll = true;
    }

    modifier onlyLake() {
        require(
            address(lake) == msg.sender,
            'LakeOwned: caller is not the Lake'
        );
        _;
    }
}

function toString(address x) pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i] = char(hi);
        s[2 * i + 1] = char(lo);
    }
    return string(abi.encodePacked('0x', string(s)));
}

function char(bytes1 b) pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
}
