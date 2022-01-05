// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '../interfaces/IOtterLake.sol';
import '../interfaces/IPearlNote.sol';
import '../interfaces/IERC20.sol';

contract MockLake is IOtterLake {
    uint256 private _epoch;

    IERC20 public immutable pearl;

    constructor(address _pearl) {
        require(_pearl != address(0));
        pearl = IERC20(_pearl);
    }

    function setEpoch(uint256 epoch_) external {
        _epoch = epoch_;
    }

    function epoch() external view override returns (uint256) {
        return _epoch;
    }

    function mint(
        address _note,
        address _user,
        uint256 _amount,
        uint256 _endEpoch
    ) external returns (uint256) {
        pearl.transferFrom(msg.sender, address(this), _amount);
        pearl.approve(_note, _amount);
        return IPearlNote(_note).mint(_user, _amount, _endEpoch);
    }

    function burn(address _note, uint256 tokenId) external returns (uint256) {
        return IPearlNote(_note).burn(tokenId);
    }

    function extendLock(
        address _note,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _endEpoch
    ) external {
        pearl.transferFrom(msg.sender, address(this), _amount);
        pearl.approve(_note, _amount);
        IPearlNote(_note).extendLock(_tokenId, _amount, _endEpoch);
    }
}
