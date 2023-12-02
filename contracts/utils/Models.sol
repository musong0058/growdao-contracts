// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Models {

    struct Bond {
        uint256 amount;
        uint256 creationTime;
        uint256 freezePeriod;
        uint256 profitPercent;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 collectedTime;
        uint256 collectedReward;
        uint256 stakingRewardLimit;
        bool isClosed;
    }

    struct User {
        address upline;
        uint8 refLevel;
        uint8 bondsNumber;
        uint256 balance;
        uint256 totalInvested;
        uint256 liquidityCreated;
        uint256 totalRefReward;
        uint256 totalWithdrawn;
        uint256 refTurnover;
        uint256 lastActionTime;
        uint256[10] refs;
        uint256[10] refsNumber;
    }

    struct BondSetting {
        bool activation;
        uint256 minBondETH;
        uint256 freezePeriod;
        uint256 profitBasis;
        uint256 firstBonus;
        uint256 timeBonus;
        uint256 start;
        uint256 end;
    }
}