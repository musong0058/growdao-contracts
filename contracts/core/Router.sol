// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./interfaces/IVault.sol";
import "../utils/Models.sol";
import "../utils/Constants.sol";
import "../access/Governable.sol";
import "../lib/math/SafeMath.sol";

contract Router is Governable {
    using SafeMath for uint256;

    address public vault;

    uint256 public stakeBonusBasis = 200;   // 2%
    uint256 public globalLiquidityBonusStepETH = 25 ether;
    uint256 public globalLiquidityBonusStepPoints = 10;     // 0.1%
    uint256 public globalLiquidityBonusLimitPoints = 10000;  // 100%
    uint256 public userHoldBonusStepTime = 1 days;
    uint256 public userHoldBonusStepPoints = 5;     // 0.05%
    uint256 public userHoldBonusLimitPoints = 200;  // 2%
    uint256 public liquidityBonusStepPoints = 5;   // 0.05%
    uint256 public liquidityBonusStepETH = 1 ether;
    uint256 public liquidityBonusLimitPoints = 200;  // 2%

    constructor(address _vault) {
        vault = _vault;
    }

    receive() external payable {
    }

    function setVault(address _vault) external onlyGov {
        vault = _vault;
    }

    function buy(address _upline, uint8 _bondType) external payable {

        Models.User memory user = IVault(vault).getUser(msg.sender);
        bool isNewUser = false;
        if(user.upline == address(0)) {
            isNewUser = true;
            if(_upline == address(0)) {
                _upline = IVault(vault).defaultUpline();
            }
        } else {
            _upline = user.upline;
        }
        uint256 refReward = IVault(vault).refRewardAmount(msg.value);
        payable(_upline).transfer(refReward);
        IVault(vault).cumulativeRefReward(_upline, refReward);
        uint256 adminFee = IVault(vault).adminFeeAmount(msg.value);
        IVault(vault).adminFeeTo().transfer(adminFee);
        uint256 liquidityAmount = msg.value - refReward - adminFee;
        payable(vault).transfer(liquidityAmount);

        Models.BondSetting memory bondSetting = IVault(vault).getBondSetting(_bondType);
        uint256 profitPoints = bondSetting.profitBasis;
        if(isNewUser) {
            profitPoints += bondSetting.firstBonus;
        }
        if(bondSetting.timeBonus > 0) {
            if(block.timestamp >= bondSetting.start && block.timestamp <= bondSetting.end) {
                profitPoints += bondSetting.timeBonus;
            }
        }

        IVault(vault).newBond(msg.sender, _upline, _bondType, msg.value, liquidityAmount, profitPoints);
    }



    function stake(uint8 _bondIdx) external payable {
        Models.Bond memory bond = IVault(vault).getBond(msg.sender, _bondIdx);
        uint256 ethAmount = bond.amount.mul(Constants.BASIS_POINTS_DIVISOR+bond.profitPercent).div(Constants.BASIS_POINTS_DIVISOR);
        require(msg.value >= ethAmount, "Stake: invalid ETH amount");

        Models.User memory user = IVault(vault).getUser(msg.sender);
        uint256 refReward = IVault(vault).refRewardAmount(msg.value);
        payable(user.upline).transfer(refReward);
        IVault(vault).cumulativeRefReward(user.upline, refReward);
        uint256 adminFee = IVault(vault).adminFeeAmount(msg.value);
        IVault(vault).adminFeeTo().transfer(adminFee);
        uint256 liquidityAmount = msg.value - refReward - adminFee;
        payable(vault).transfer(liquidityAmount);

        IVault(vault).stake(msg.sender, _bondIdx, msg.value, liquidityAmount);
    }

    function claim(uint256 tokenAmount) external {
        require(IVault(vault).userBalance(msg.sender) >= tokenAmount, "Claim: insufficient balance");
        IVault(vault).claim(msg.sender, tokenAmount);
    }

    function rebond(uint8 bondIndex, uint256 tokenAmount) external {
        IVault(vault).rebond(msg.sender, bondIndex, tokenAmount);
    }

    function sell(uint256 tokenAmount) external {
        IVault(vault).sell(msg.sender, tokenAmount);
    }

    function userBalance(address _account) external view returns (uint256 balance) {
        balance = IVault(vault).userBalance(_account);
    }

    function userData(address _account) external view returns (
        Models.User memory user,
        uint256 userTokenBalance,
        uint256 userHoldBonus,
        uint256 userLiquidityBonus,
        uint256 globalLiquidityBonus
    ) {
        (user, userTokenBalance, userHoldBonus, userLiquidityBonus, globalLiquidityBonus) = IVault(vault).userData(_account);
    }

}