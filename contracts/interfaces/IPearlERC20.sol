// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './IERC20.sol';

interface IPearlERC20 is IERC20 {
    /**
        @notice wrap sCLAM
        @param _amount uint
        @return uint
     */
    function wrap(uint256 _amount) external returns (uint256);

    /**
        @notice unwrap sCLAM
        @param _amount uint
        @return uint
     */
    function unwrap(uint256 _amount) external returns (uint256);

    /**
        @notice converts PEARL amount to sCLAM
        @param _amount uint
        @return uint
     */
    function pearlTosCLAM(uint256 _amount) external view returns (uint256);

    /**
        @notice converts sCLAM amount to PEARL
        @param _amount uint
        @return uint
     */
    function sCLAMToPEARL(uint256 _amount) external view returns (uint256);
}
