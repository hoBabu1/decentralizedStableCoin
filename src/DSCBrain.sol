// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/**
 * @title DSCBrain
 * @author Aman Kumar aka hoBabu aka Dhanyosmi
 *
 * This system is designed to be as minimal as possible and have tokens maintain a 1 token == $1 peg.
 * Properties of this stable coin :
 * - Dollar pegged (Anchored or Pegged)
 * - Exogenous (Collateral comes from outside the stablecoin's ecosystem. If stablecoin fails, collateral is unaffecte )
 * - Algorithimically Stable
 *
 * It is similar to DAI if DAI had no governence, no fees, and was backed by WETH and WBTC
 * Our DSC system will be overcolletralized . At no point, should thr value of all colletral <= the value of all the DSC
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing and withdrawing colletral.
 * @notice This contract is VERY loosely based on DAI system.
 */

contract DSCBrain is ReentrancyGuard {
    /////////////////////////
    /// Errors //////////////
    ////////////////////////

    error DSCBrain__DepositColletralShouldBeMoreThanZero();
    error DSCBrain__TokenAddressAndPriceFeedAddressLengthMustBeSame();
    error DSCBrain__ThisTokenIsNotAllowed();
    error DSCBrain__TransferOfTokenFailedFromUsersAccountToContract();
    error DSCBrain__HealthIsNotGoodGoToDoctor(uint256 healthFactor);
    error DSCBrain__MintingFailed();

    /////////////////////////
    // State variable //////
    ////////////////////////
    uint256 private constant ADDRESS_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESOLD = 50; // 200% overcolletralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeed;
    DecentralizedStableCoin private immutable i_dsc;
    mapping(address user => mapping(address token => uint256 amount)) private s_colletralDeposit;
    mapping(address user => uint256 DscMinted) private s_DscMinted;
    address[] private s_colletralToken;

    /////////////////////////
    /// EVENTS///////////////
    ////////////////////////

    event colletrlDeposit(address indexed user, address indexed token, uint256 indexed amount);

    /////////////////////////
    /// MODIFIERS //////////
    ////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCBrain__DepositColletralShouldBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address ofToken) {
        if (s_priceFeed[ofToken] == address(0)) {
            revert DSCBrain__ThisTokenIsNotAllowed();
        }
        _;
    }

    /**
     * @param tokenAddresses Token address of BTC,ETH
     * @param priceFeedAddresses PriceFeed address from chain Link
     * @param dscAddress DecentralizedStableCoin contract address because it will be called for minitng and buring of DAI
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCBrain__TokenAddressAndPriceFeedAddressLengthMustBeSame();
        }

        for (uint256 i = 0; i <tokenAddresses.length; i++) {
            s_priceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
            s_colletralToken.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////////
    // External Functions ///
    ////////////////////////

    function depositColletralAndMintDSC() external {}

    /**
     * @notice CEI - check effects Interaction
     * @param tokenColletralAddress - The address of the token to deposit as a colletral
     * @param amountColletral - The amount of colletral to deposit
     */
    function depositColletral(address tokenColletralAddress, uint256 amountColletral)
        external
        moreThanZero(amountColletral)
        isAllowedToken(tokenColletralAddress)
        nonReentrant
    {
        s_colletralDeposit[msg.sender][tokenColletralAddress] += amountColletral;
        emit colletrlDeposit(msg.sender, tokenColletralAddress, amountColletral);
        bool success = IERC20(tokenColletralAddress).transferFrom(msg.sender, address(this), amountColletral);
        if (!success) {
            revert DSCBrain__TransferOfTokenFailedFromUsersAccountToContract();
        }
    }

    function reedemColletral() external {}

    function reedemColletralForDSC() external {}
    /**
     * @notice Folllows CEI
     * @notice They must have colletral value less than minimum therehold
     * @param amountDscToMint The amount of Decentralized stable coin to mint.
     *
     */

    function mintDSC(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DscMinted[msg.sender] += amountDscToMint;
        _revertHealthFactorIsBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCBrain__MintingFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
    ///////////////////////////////////////
    // private & internal view Functions///
    //////////////////////////////////////

    function _getAccountInfoOfUser(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 colletralValueInUSD)
    {
        totalDscMinted = s_DscMinted[user];
        colletralValueInUSD = getColletralValueInUSD(user);
    }
    /**
     * Returns how close a person is about to liquidate
     * If user gets below 1 then they can get liquidated
     */

    function _healthFactor(address user) private view returns (uint256) {
        // calculte how much they have deposited
        // get how much they have deposited what
        // convert it into usd and add it
        // check they have minted how much --> mint amount should be less then colletral
        (uint256 totalDscMinted, uint256 colletralValueInUSD) = _getAccountInfoOfUser(user);
        uint256 colletralAdjustedForThreshold = (colletralValueInUSD * LIQUIDATION_THRESOLD) / 100;
        return (colletralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // return (colletralValueInUSD/totalDscMinted);
    }
    /**
     * @param user - User whose health factor will be checked
     *  check do they have enough colletral
     *  Revert if they dont have
     */

    function _revertHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCBrain__HealthIsNotGoodGoToDoctor(userHealthFactor);
        }
    }

    ///////////////////////////////////////
    // public & internal view Functions///
    //////////////////////////////////////

    /**
     * @param user address of user
     * @return totalColletralValueInUSD Returns the Total Colletral Value in USD
     */
    function getColletralValueInUSD(address user) public view returns (uint256 totalColletralValueInUSD) {
        // loop through all token
        //get amount*price
        for (uint256 i = 0; i < s_colletralToken.length; i++) {
            address token = s_colletralToken[i];
            uint256 amount = s_colletralDeposit[user][token];
            totalColletralValueInUSD += getValueinUsd(token, amount);
        }
        return totalColletralValueInUSD;
    }

    /**
     * @param token address of token like wBTC , wETH
     * @param amount Collteral of specific token
     * @return - It returns the colletral into USD
     *  Using `AggregatorV3Interface` to get the price of 1ETH/1BTC in terms of USDC, Total amount of wBTC/wETH * price
     */
    function getValueinUsd(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (uint256(price) * ADDRESS_FEED_PRECISION) * amount / PRECISION;
    }
}
