// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../access/ReentrancyGuard.sol";
import "./interfaces/IVault.sol";
import "../utils/Models.sol";
import "../utils/Events.sol";
import "../utils/Constants.sol";
import "../token/extensions/GROWToken.sol";
import "../amm/IUniswapV2Pair.sol";
import "../amm/IUniswapV2Router01.sol";

contract Vault is ReentrancyGuard, IVault {
    using SafeMath for uint256;

    address public override dexRouter;
    address public override dexLpToken;
    address public override bondToken;
    address public override wrappedETH;
    uint256 public override maxBondNumber = 100;
    uint256 public override minBondTokenAmount = 100 ether;
//    uint256 public override minBondETH = 0.001 ether;
//    uint256 public override minBondToken = 100 ether;

    bool public override isInitialized;
    bool public override isGlobalEnabled = true;
    bool public override isSellEnabled = true;
    bool public override isClaimEnabled = true;

    address public override gov;
    address payable public override adminFeeTo;
    address payable public override defaultUpline;

    uint256 public override adminFeePoints = 1000;      // 10%
    uint256 public override refRewardPoints = 500;      // 5%
    uint256 public override claimTaxPoints = 2000;      // 20%
    uint256 public override sellTaxPoints = 2000;       // 20%

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
    uint256 public priceBalancerPoints = 100;       // 10%

    // all bonds
    mapping(bytes32 => Models.Bond) public bonds;
    // all users
    mapping(address => Models.User) public users;
    // bond keys for each user
    mapping(address => bytes32[]) public bondKeys;
    // referrals for each user
    mapping(address => address[]) public referrals;
    // approved routers
    mapping(address => bool) public approvedRouters;
    // setting up of all bond classes
    mapping(uint8 => Models.BondSetting) public bondSettings;


    constructor() {
        gov = msg.sender;
    }

    receive() external payable {
    }

    function initialize(
        address _dexRouter,
        address _dexLpToken,
        address _bondToken,
        address _wrappedETH,
        address _adminFeeTo,
        address _defaultUpline) external {
        _onlyGov();
        require(!isInitialized, "Vault: already initialized");
        isInitialized = true;

        dexRouter = _dexRouter;
        dexLpToken = _dexLpToken;
        bondToken = _bondToken;
        wrappedETH = _wrappedETH;
        adminFeeTo = payable(_adminFeeTo);
        defaultUpline = payable(_defaultUpline);
    }

    function setGov(address _gov) external {
        _onlyGov();
        gov = _gov;
    }

    function setAdminFeeTo(address _feeTo) external {
        _onlyGov();
        adminFeeTo = payable(_feeTo);
    }

    function setDefaultUpline(address _upline) external {
        _onlyGov();
        defaultUpline = payable(_upline);
    }

    function setDexRouter(address _dexRouter) external override {
        _onlyGov();
        dexRouter = _dexRouter;
    }

    function setDexLpToken(address _dexLpToken) external override {
        _onlyGov();
        dexLpToken = _dexLpToken;
    }

    function setBondToken(address _bondToken) external override {
        _onlyGov();
        bondToken = _bondToken;
    }

    function setWrappedETH(address _wrappedETH) external override {
        _onlyGov();
        wrappedETH = _wrappedETH;
    }

    function setMaxBondNumber(uint256 _maxBondNumber) external override {
        _onlyGov();
        maxBondNumber = _maxBondNumber;
    }

//    function setMinBondETH(uint256 _minBondETH) external override {
//        _onlyGov();
//        minBondETH = _minBondETH;
//    }
//
//    function setMinBondToken(uint256 _minBondToken) external override {
//        _onlyGov();
//        minBondToken = _minBondToken;
//    }

    function setIsGlobalEnabled(bool _isGlobalEnabled) external override {
        _onlyGov();
        isGlobalEnabled = _isGlobalEnabled;
    }

    function setIsSellEnabled(bool _isSellEnabled) external override {
        _onlyGov();
        isSellEnabled = _isSellEnabled;
    }

    function setIsClaimEnabled(bool _isClaimEnabled) external override {
        _onlyGov();
        isClaimEnabled = _isClaimEnabled;
    }

    function setFees(
        uint256 _adminFeePoints,
        uint256 _refRewardPoints,
        uint256 _claimTaxPoints,
        uint256 _sellTaxPoints
    ) external override {
        _onlyGov();
        adminFeePoints = _adminFeePoints;
        refRewardPoints = _refRewardPoints;
        claimTaxPoints = _claimTaxPoints;
        sellTaxPoints = _sellTaxPoints;
    }

    function addRouter(address _router) external override {
        _onlyGov();
        approvedRouters[_router] = true;
    }

    function removeRouter(address _router) external override {
        _onlyGov();
        approvedRouters[_router] = false;
    }

    function setBondSetting(uint8 _bondType, Models.BondSetting memory _bondSetting) external override {
        _onlyGov();
        bondSettings[_bondType] = _bondSetting;
    }

    function newBond(
        address _account,
        address _upline,
        uint8 _bondType,
        uint256 _bondAmount,
        uint256 _liquidityAmount,
        uint256 _profitAmount
    ) public override returns (uint8) {
        _onlyApproved();
        _validateBondActivation(_bondType);
        _validateBondNumber(_account);
        _validateBondAmount(_bondType, _bondAmount);

        Models.User storage user = users[_account];
        bytes32 bondKey = getBondKey(_account, uint256(user.bondsNumber));
        Models.Bond storage bond = bonds[bondKey];

        bond.freezePeriod = bondSettings[_bondType].freezePeriod;
        bond.profitPercent = _profitAmount;
        bond.amount = _bondAmount;
        bond.creationTime = block.timestamp;

        if (user.bondsNumber == 0) {
            user.lastActionTime = block.timestamp;
        }

        user.bondsNumber ++;
        user.totalInvested += _bondAmount;
        if (user.upline == address(0)) {
            user.upline = _upline;
        }
        bondKeys[_account].push(bondKey);

        uint256 tokenAmount = 0;
        if (_liquidityAmount > 0) {
//            tokenAmount = getTokenAmount(_liquidityAmount);
//            GROWToken(bondToken).mint(address(this), tokenAmount);
//            GROWToken(bondToken).increaseAllowance(dexRouter, tokenAmount);
//
//            (uint256 amountToken, uint256 amountETH, uint256 liquidity) =
//            IUniswapV2Router01(dexRouter).addLiquidityETH {value: _liquidityAmount} (
//                bondToken,
//                tokenAmount,
//                0,
//                0,
//                address(this),
//                block.timestamp + 5 minutes
//            );
//
//            emit Events.LiquidityAdded(
//                amountToken, amountETH, liquidity, block.timestamp
//            );
        }

        emit Events.NewBond(
            _account, _bondType, user.bondsNumber - 1, _bondAmount, tokenAmount, _liquidityAmount == 0, block.timestamp
        );

        return user.bondsNumber - 1;
    }

    function stake(address _account, uint8 _bondIdx, uint256 _msgValue, uint256 _liquidityETHAmount) external {
        _onlyApproved();
        require(_bondIdx < users[_account].bondsNumber, "Vault: invalid bond index");
        require(!bonds[bondKeys[_account][_bondIdx]].isClosed, "Vault: this bond already closed");
        require(bonds[bondKeys[_account][_bondIdx]].stakeTime == 0, "Vault: this bond was already staked");
        require(_liquidityETHAmount > 0, "Vault: invalid ETH amount");

        Models.User storage user = users[_account];
        Models.Bond storage bond  = bonds[bondKeys[_account][_bondIdx]];

        uint256 ethAmount = bond.amount.mul(Constants.BASIS_POINTS_DIVISOR+bond.profitPercent).div(Constants.BASIS_POINTS_DIVISOR);
        uint256 tokenAmount = ethAmount.mul(100000);
//        uint256 liquidityTokenAmount = _liquidityETHAmount.mul(100000);
        //        uint256 tokenAmount = getTokenAmount(ethAmount);
//        uint256 liquidityTokenAmount = getTokenAmount(_liquidityETHAmount);
//
//        GROWToken(bondToken).mint(address(this), liquidityTokenAmount);
//        GROWToken(bondToken).increaseAllowance(dexRouter, liquidityTokenAmount);
//
//        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IUniswapV2Router01(dexRouter).addLiquidityETH {value: _liquidityETHAmount} (
//            bondToken,
//            liquidityTokenAmount,
//            0,
//            0,
//            address(this),
//            block.timestamp + 5 minutes
//        );

        user.liquidityCreated += _msgValue;

//        emit Events.LiquidityAdded(
//            amountToken, amountETH, liquidity, block.timestamp
//        );

        bond.stakeAmount = 2 * tokenAmount;
        bond.stakeTime = block.timestamp;
        bond.collectedTime = block.timestamp;
        bond.stakingRewardLimit = bond.stakeAmount.mul(Constants.STAKING_REWARD_LIMIT_PERCENT).div(Constants.BASIS_POINTS_DIVISOR);

        emit Events.StakeBond(
            _account, _bondIdx, tokenAmount, _msgValue, block.timestamp
        );
    }

    function claim(address _account, uint256 _tokenAmount) external {
        _onlyApproved();
        _validateGlobalEnabled();

        collect(_account);
        Models.User storage user = users[_account];
        require(user.balance >= _tokenAmount, "Claim: insufficient balance");

        user.balance -= _tokenAmount;
        user.lastActionTime = block.timestamp;
        GROWToken(bondToken).mint(_account, _tokenAmount);

        emit Events.Claim(
            _account, _tokenAmount, block.timestamp
        );
    }

    function rebond(address _account, uint8 _bondIdx, uint256 _tokenAmount) external {
        require(users[msg.sender].bondsNumber < maxBondNumber, "Rebond: you have reached bonds limit");
        require(_tokenAmount >= minBondTokenAmount, "Rebond: less than min rebond token amount");
        require(userBalance(_account) >= _tokenAmount, "Rebond: insufficient balance");

        collect(_account);
        Models.User storage user = users[_account];
        require(user.balance >= _tokenAmount, "Rebond: insufficient balance");

        user.balance -= _tokenAmount;

        uint256 ethAmount = getETHAmount(_tokenAmount);
        uint8 bondIdx = newBond(_account, defaultUpline, _bondIdx, ethAmount, 0, bondSettings[_bondIdx].profitBasis);

        emit Events.ReBond(
            _account, bondIdx, ethAmount, _tokenAmount, block.timestamp
        );
    }

    function sell(address _account, uint256 _tokenAmount) external {
        _onlyApproved();
        _validateGlobalEnabled();

        collect(_account);
        Models.User storage user = users[_account];
        require(user.balance >= _tokenAmount, "Sell: insufficient balance");

        user.balance -= _tokenAmount;
        user.lastActionTime = block.timestamp;

        address[] memory path = new address[](2);
        path[0] = bondToken;
        path[1] = wrappedETH;

//        GROWToken(bondToken).mint(address(this), _tokenAmount);
//        GROWToken(bondToken).increaseAllowance(dexRouter, _tokenAmount);
//
//        uint256[] memory amounts = IUniswapV2Router01(dexRouter).swapExactTokensForETH(
//            _tokenAmount,
//            0,
//            path,
//            _account,
//            block.timestamp + 5 minutes
//        );
//        uint256 ethAmount = amounts[1];
//
//        (uint256 ethReserved, ) = getTokenLiquidity();
//        uint256 liquidity = ERC20(dexLpToken).totalSupply()
//        * ethAmount
//        * (Constants.BASIS_POINTS_DIVISOR + priceBalancerPoints)
//        / Constants.BASIS_POINTS_DIVISOR
//        / ethReserved;
//
//        ERC20(dexLpToken).approve(
//            dexRouter,
//            liquidity
//        );
//
//        (, uint256 amountETH) = IUniswapV2Router01(dexRouter).removeLiquidityETH(
//            bondToken,
//            liquidity,
//            0,
//            0,
//            address(this),
//            block.timestamp + 5 minutes
//        );
//
//        path[0] = wrappedETH;
//        path[1] = bondToken;
//        amounts = IUniswapV2Router01(dexRouter).swapExactETHForTokens {value: amountETH} (
//            0,
//            path,
//            address(this),
//            block.timestamp + 5 minutes
//        );
//
//        emit Events.Sell(
//            _account, _tokenAmount, ethAmount, block.timestamp
//        );
    }

    function userBalance(address _account) public view returns (uint256 balance) {
        Models.User memory user = users[_account];

        uint8 bondsNumber = user.bondsNumber;
        for (uint8 i = 0; i < bondsNumber; i++) {
            if (bonds[bondKeys[_account][i]].isClosed) {
                continue;
            }

            Models.Bond memory bond = bonds[bondKeys[_account][i]];

            uint256 tokenAmount;
            if (bond.stakeTime == 0) {
                if (block.timestamp >= bond.creationTime + bond.freezePeriod) {
                    tokenAmount = getTokenAmount(bond.amount.mul(bond.profitPercent.add(Constants.BASIS_POINTS_DIVISOR)).div(Constants.BASIS_POINTS_DIVISOR));
                    balance += tokenAmount;
                }
            } else {
                tokenAmount = bond.stakeAmount
                * (block.timestamp - bond.collectedTime)
                * (
                stakeBonusBasis
                + getLiquidityGlobalBonusPercent()
                + getHoldBonusPercent(_account)
                + getLiquidityBonusPercent(_account)
                )
                / Constants.BASIS_POINTS_DIVISOR
                / 1 days;

                if (bond.collectedReward + tokenAmount >= bond.stakingRewardLimit) {
                    tokenAmount = bond.stakingRewardLimit - bond.collectedReward;
                }

                balance += tokenAmount;
            }
        }

        balance += user.balance;
    }

    function collect(address _account) private {
        Models.User storage user = users[_account];

        uint8 bondsNumber = user.bondsNumber;
        for (uint8 i = 0; i < bondsNumber; i++) {
            if (bonds[bondKeys[_account][i]].isClosed) {
                continue;
            }

            Models.Bond storage bond = bonds[bondKeys[_account][i]];

            uint256 tokenAmount;
            if (bond.stakeTime == 0) {
                if (block.timestamp >= bond.creationTime + bond.freezePeriod) {
                    tokenAmount = getTokenAmount(bond.amount * (Constants.BASIS_POINTS_DIVISOR + bond.profitPercent) / Constants.BASIS_POINTS_DIVISOR);

                    user.balance += tokenAmount;
                    bond.isClosed = true;
                }
            } else {
                tokenAmount = bond.stakeAmount
                * (block.timestamp - bond.collectedTime)
                * (
                stakeBonusBasis
                + getLiquidityGlobalBonusPercent()
                + getHoldBonusPercent(_account)
                + getLiquidityBonusPercent(_account)
                )
                / Constants.BASIS_POINTS_DIVISOR
                / 1 days;

                if (bond.collectedReward + tokenAmount >= bond.stakingRewardLimit) {
                    tokenAmount = bond.stakingRewardLimit - bond.collectedReward;
                    bond.collectedReward = bond.stakingRewardLimit;
                    bond.isClosed = true;
                } else {
                    bond.collectedReward += tokenAmount;
                }

                user.balance += tokenAmount;
                bond.collectedTime = block.timestamp;
            }
        }
    }

    function getLiquidityGlobalBonusPercent() public view returns (uint256 bonusPercent) {
        (uint256 liquidityETH, ) = getTokenLiquidity();

        bonusPercent = liquidityETH
        * globalLiquidityBonusStepPoints
        / globalLiquidityBonusStepETH;

        if (bonusPercent > globalLiquidityBonusLimitPoints) {
            return globalLiquidityBonusLimitPoints;
        }
    }

    function getHoldBonusPercent(address _account) public view returns (uint256 bonusPercent) {
        Models.User memory user = users[_account];
        if (user.lastActionTime == 0) {
            return 0;
        }

        bonusPercent = (block.timestamp - user.lastActionTime)
        * userHoldBonusStepPoints
        / userHoldBonusStepTime;

        if (bonusPercent > userHoldBonusLimitPoints) {
            return userHoldBonusLimitPoints;
        }
    }

    function getLiquidityBonusPercent(address _account) public view returns (uint256 bonusPercent) {
        Models.User memory user = users[_account];
        bonusPercent = user.liquidityCreated
        * liquidityBonusStepPoints
        / liquidityBonusStepETH;

        if (bonusPercent > liquidityBonusLimitPoints) {
            return liquidityBonusLimitPoints;
        }
    }

    function getBondKey(address _account, uint256 _bondNumber) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _bondNumber));
    }

    function getTokenLiquidity() public view returns (
        uint256 liquidityETH,
        uint256 liquidityERC20
    ) {
//        (liquidityETH, liquidityERC20, ) = IUniswapV2Pair(dexLpToken).getReserves();
    liquidityETH = 1 ether;
    liquidityERC20 = 100 ether;
    }

    function userData(address _account) external view returns (
        Models.User memory user,
        uint256 userTokenBalance,
        uint256 userHoldBonus,
        uint256 userLiquidityBonus,
        uint256 globalLiquidityBonus
    ) {
        user = users[_account];
        userTokenBalance = userBalance(_account);
        userHoldBonus = getHoldBonusPercent(_account);
        userLiquidityBonus = getLiquidityBonusPercent(_account);
        globalLiquidityBonus = getLiquidityGlobalBonusPercent();
    }

    function getETHAmount(uint256 tokenAmount) public view returns(uint256) {
//        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(dexLpToken).getReserves();
//
//        return tokenAmount * reserve0 / reserve1;
        return tokenAmount.div(100);
    }

    function getTokenAmount(uint256 amount) public view returns (uint256) {
//        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(dexLpToken).getReserves();
//
//        return amount * reserve1 / reserve0;
        return amount.mul(100);
    }

    function getBondSetting(uint8 _bondType) external view returns (Models.BondSetting memory _bondSetting) {
        _bondSetting = bondSettings[_bondType];
    }

    function adminFeeAmount(uint256 _amount) external view returns (uint256) {
        return _amount.mul(adminFeePoints).div(Constants.BASIS_POINTS_DIVISOR);
    }

    function refRewardAmount(uint256 _amount) external view returns (uint256) {
        return _amount.mul(refRewardPoints).div(Constants.BASIS_POINTS_DIVISOR);
    }

    function cumulativeRefReward(address _account, uint256 _amount) external {
        _onlyApproved();
        users[_account].totalRefReward += _amount;
    }

    function getUser(address _account) external view returns (Models.User memory user) {
        user = users[_account];
    }

    function getBond(address _account, uint256 _index) external view returns (Models.Bond memory bond) {
        bond = bonds[getBondKey(_account, _index)];
    }

    function _onlyGov() private view {
        require(msg.sender == gov, "Vault: forbidden");
    }

    function _onlyApproved() private view {
        require(approvedRouters[msg.sender], "Vault: router forbidden");
    }

    function _validateGlobalEnabled() private view {
        require(isGlobalEnabled, "Vault: globally forbidden");
    }

    function _validateBondActivation(uint8 _bondType) private view {
        require(bondSettings[_bondType].activation, "Vault: bond inactive");
    }

    function _validateBondNumber(address _account) private view {
        require(users[_account].bondsNumber < maxBondNumber, "Vault: number of bonds exceeded");
    }

    function _validateBondAmount(uint8 _bondType, uint256 _bondAmount) private view {
        require(_bondAmount >= bondSettings[_bondType].minBondETH, "Vault: less than min eth");
    }

}