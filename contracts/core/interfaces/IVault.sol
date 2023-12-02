// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../../utils/Models.sol";

interface IVault {

    function dexRouter() external view returns (address);
    function dexLpToken() external view returns (address);
    function bondToken() external view returns (address);
    function wrappedETH() external view returns (address);
    function maxBondNumber() external view returns (uint256);
    function minBondTokenAmount() external view returns (uint256);

//    function minBondETH() external view returns (uint256);
//    function minBondToken() external view returns (uint256);

    function isInitialized() external view returns (bool);
    function isGlobalEnabled() external view returns (bool);
    function isSellEnabled() external view returns (bool);
    function isClaimEnabled() external view returns (bool);

    function gov() external view returns (address);
    function adminFeeTo() external view returns (address payable);
    function defaultUpline() external view returns (address payable);

    function adminFeePoints() external view returns (uint256);
    function refRewardPoints() external view returns (uint256);
    function claimTaxPoints() external view returns (uint256);
    function sellTaxPoints() external view returns (uint256);

    function approvedRouters(address _router) external view returns (bool);

    function setDexRouter(address _dexRouter) external;
    function setDexLpToken(address _dexLpToken) external;
    function setBondToken(address _bondToken) external;
    function setWrappedETH(address _wrappedETH) external;
    function setMaxBondNumber(uint256 _maxBondNumber) external;
//    function setMinBondETH(uint256 _minBondETH) external;
//    function setMinBondToken(uint256 _minBondToken) external;
    function setIsGlobalEnabled(bool _isGlobalEnabled) external;
    function setIsSellEnabled(bool _isSellEnabled) external;
    function setIsClaimEnabled(bool _isClaimEnabled) external;
    function setFees(uint256 _adminFeePoints,
        uint256 _refRewardPoints,
        uint256 _claimTaxPoints,
        uint256 _sellTaxPoints) external;
    function addRouter(address _router) external;
    function removeRouter(address _router) external;
    function setBondSetting(uint8 _bondType, Models.BondSetting memory _bondSetting) external;
    function getBondSetting(uint8 _bondType) external view returns (Models.BondSetting memory);
    function adminFeeAmount(uint256 _amount) external view returns (uint256);
    function refRewardAmount(uint256 _amount) external view returns (uint256);
    function cumulativeRefReward(address _account, uint256 _amount) external;
    function getTokenLiquidity() external view returns (uint256, uint256);
    function getTokenAmount(uint256 amount) external view returns (uint256);
    function getUser(address _account) external view returns (Models.User memory);
    function getBond(address _account, uint256 _index) external view returns (Models.Bond memory);

    function newBond(address _account, address _upline, uint8 bondType, uint256 bondAmount, uint256 liquidityAmount, uint256 profitAmount) external returns (uint8);
    function stake(address _account, uint8 _bondIdx, uint256 _msgValue, uint256 _liquidityETHAmount) external;
    function claim(address _account, uint256 _tokenAmount) external;
    function rebond(address _account, uint8 _bondIdx, uint256 _tokenAmount) external;
    function sell(address _account, uint256 _tokenAmount) external;
    function userBalance(address _account) external view returns (uint256);
    function userData(address _account) external view returns (Models.User memory, uint256, uint256, uint256, uint256);

}