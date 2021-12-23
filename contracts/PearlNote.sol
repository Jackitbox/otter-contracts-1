// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './interfaces/IPearlNote.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPearlVault.sol';

contract PearlNote is IPearlNote, ERC721 {
    struct LockInfo {
        uint256 amount;
        uint256 endEpoch;
    }

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 public immutable pearl;
    IPearlVault public immutable vault;

    // token id => lock info
    mapping(uint256 => LockInfo) public lockInfos;
    Counters.Counter private _tokenIdTracker;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address _pearl,
        address _vault
    ) ERC721(name, symbol) {
        _setBaseURI(baseURI);

        require(_pearl != address(0));
        pearl = IERC20(_pearl);
        require(_vault != address(0));
        vault = IPearlVault(_vault);
    }

    function nextTokenId() external view override returns (uint256) {
        return _tokenIdTracker.current();
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

    function mint(
        address _user,
        uint256 _amount,
        uint256 _endEpoch
    ) external override onlyVault returns (uint256) {
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
        onlyVault
        returns (uint256)
    {
        LockInfo memory lockInfo = lockInfos[tokenId];
        require(
            lockInfo.endEpoch <= vault.epoch(),
            'PearlNote: the note is not expired'
        );
        address owner = ownerOf(tokenId);
        pearl.transfer(owner, lockInfo.amount);
        _burn(tokenId);
        return lockInfo.amount;
    }

    function extendLock(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _endEpoch
    ) external override onlyVault {
        LockInfo storage lockInfo = lockInfos[_tokenId];
        pearl.transferFrom(msg.sender, address(this), _amount);
        lockInfo.amount = lockInfo.amount.add(_amount);
        lockInfo.endEpoch = _endEpoch;
    }

    modifier onlyVault() {
        require(
            address(vault) == msg.sender,
            'VaultOwned: caller is not the Vault'
        );
        _;
    }
}
