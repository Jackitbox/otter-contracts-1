// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IOtto {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);
}
