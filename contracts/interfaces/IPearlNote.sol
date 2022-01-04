// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IPearlNote is IERC721 {
    function lockAmount(uint256 tokenId) external view returns (uint256);

    function endEpoch(uint256 tokenId) external view returns (uint256);

    /// @dev Extend the NFT lock period
    /// @param _tokenId the token id need to extend
    /// @param _amount The extra lock amount
    /// @param _endEpoch The lock due date
    function extendLock(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _endEpoch
    ) external;

    /// @dev Mint a new ERC721 to represent receipt of lock
    /// @param _user The locker, who will receive this token
    /// @param _amount The lock amount
    /// @param _endEpoch The lock due date
    /// @return token id minted
    function mint(
        address _user,
        uint256 _amount,
        uint256 _endEpoch
    ) external returns (uint256);

    /// @dev Burn the NFT and get token locked inside back
    /// @param tokenId the token id which got burned
    /// @return the amount of unlocked token
    function burn(uint256 tokenId) external returns (uint256);
}
