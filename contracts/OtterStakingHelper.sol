// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

contract OtterStakingHelper {

    address public immutable staking;
    address public immutable CLAM;

    constructor ( address _staking, address _CLAM ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _CLAM != address(0) );
        CLAM = _CLAM;
    }

    function stake( uint _amount ) external {
        IERC20( CLAM ).transferFrom( msg.sender, address(this), _amount );
        IERC20( CLAM ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}
