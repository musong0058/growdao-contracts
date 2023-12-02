// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Events {

    event NewBond(
        address indexed account,
        uint8 indexed bondType,
        uint8 indexed bondIndex,
        uint256 amount,
        uint256 tokenAmount,
        bool isRebond,
        uint256 time
    );

    event ReBond(
        address indexed account,
        uint8 indexed bondIndex,
        uint256 amount,
        uint256 tokenAmount,
        uint256 time
    );

    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        uint256 time
    );

    event StakeBond(
        address indexed account,
        uint8 indexed bondIndex,
        uint256 amountToken,
        uint256 amountETH,
        uint256 time
    );

    event Claim(
        address indexed account,
        uint256 tokenAmount,
        uint256 time
    );

    event Sell(
        address indexed account,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 time
    );
}