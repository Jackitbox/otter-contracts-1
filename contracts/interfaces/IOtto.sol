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

    event OpenPortal(
        address indexed sender_,
        uint256 tokenId_,
        bool legendary_
    );

    event SummonOtto(
        address indexed sender_,
        uint256 tokenId_,
        bool legendary_
    );

    function exists(uint256 tokenId_) external view returns (bool);

    function canOpenAt(uint256 tokenId_) external view returns (uint256);

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function setOpenPeriod(uint256 openPeriod_) external;

    function setTraits(uint256 tokenId_, uint256 traits_) external;

    function portalStatusOf(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidatesOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function traitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory arr_);
}
