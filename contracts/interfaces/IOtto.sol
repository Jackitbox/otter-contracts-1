// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IOtto {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);
}

interface IOttoV2 is IOtto {
    enum PortalStatus {
        UNOPENED,
        OPENED,
        SUMMONED
    }

    event BaseURIChanged(address indexed sender_, string baseURI_);

    function exists(uint256 tokenId_) external view returns (bool);

    function canSummonAt(uint256 tokenId_) external view returns (uint256);

    event PortalOpened(
        address indexed who_,
        uint256 tokenId_,
        uint256[] candidates_,
        bool legendary_
    );

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    event OttoSummoned(
        address indexed who_,
        uint256 tokenId_,
        uint256 traits_,
        uint256 birthday_
    );

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function setSummonPeriod(uint256 summonPeriod_) external;

    function portalStatus(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidates(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function U16toU256(uint16[16] memory arr_)
        external
        pure
        returns (uint256 traits_);

    function U256toU16(uint256 traits_)
        external
        pure
        returns (uint16[16] memory arr_);
}
