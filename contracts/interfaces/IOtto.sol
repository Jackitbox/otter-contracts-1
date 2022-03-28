// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IOtto {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);
}

interface IOttoV2 is IOtto {
    function minted(uint256 tokenId_) external view returns (bool);

    function canSummonTimestamp(uint256 tokenId_)
        external
        view
        returns (uint256);

    function setSummonPeriod(uint256 summonPeriod_) external;

    function U16toU256(uint16[16] memory arr_)
        external
        pure
        returns (uint256 traits_);

    function U256toU16(uint256 traits_)
        external
        pure
        returns (uint16[16] memory arr_);
}
