// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {StableCoin} from "./StableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Spencer Wilfahrt
 * 
 * Tokens are designed to maintain a $1 peg and has the following properties:
 * - Exogenous collateral (wBTC, wETH)
 * - Algorithmically stable
 * 
 * Design is similar to DAI with the following caveats:
 *  - No governance
 *  - No fees
 *  - Only backed by wETH and wBTC
 * 
 * DSC system is always overcollateralized. Value of collateral will never be less than the backed value of DSC.
 * 
 * @notice This contract handles the core logic of the DSC system, including minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {

    ////////////////
    // Errors /////
    ///////////////

    error DSCEngine__MintFailed();
    error DSCEngine__LessThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TokenTransferFailed();
    error DSCEngine__BreaksHealthFactor(uint healthFactor);


    ////////////////////////
    // State variables /////
    /////////////////////// 

    uint private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint private constant PRECISION = 1e18;
    uint private constant LIQUIDATION_THRESHOLD = 50;
    uint private constant LIQUIDATION_PRECISION = 100;
    uint private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint amount)) 
    private s_collateralDeposited;
    mapping(address user => uint amountDscMinted) private s_amountDSCMinted;
    address[] private s_collateralTokens;

    StableCoin private immutable i_stableCoin;

    ////////////////
    // Events /////
    ///////////////

    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint indexed amount
    );

    ////////////////
    // Modifiers //
    ///////////////

    modifier moreThanZero(uint amount) {
        if (amount <= 0) {
            revert DSCEngine__LessThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    ////////////////
    // Functions //
    ///////////////

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_stableCoin = StableCoin(dscAddress);
    }

     ///////////////////////
    // External functions //
    ////////////////////////

    function depositCollateralAndMintDSC() external {}

    /**
     * @notice follows CEI (checks, effects, interactions) pattern
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral  The amount of collateral to deposit
     */
    function depositCollateral(
        address tokenCollateralAddress, 
        uint amountCollateral
        ) external 
        moreThanZero(amountCollateral) 
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
        {
            s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
            emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
            bool s = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
            if (!s) {
                revert DSCEngine__TokenTransferFailed();
            }

        }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}


    /**
     * @notice follows CEI
     * @param amountDscToMint The amount of DSC to mint
     * @notice user must have more collateral value than minimum threshold
     */
    function mintDSC(uint amountDscToMint) external moreThanZero(amountDscToMint) {
        s_amountDSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_stableCoin.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ////////////////////////////////////
    // Private and Internal functions //
    ///////////////////////////////////

    /**
     * Returns how close a user is to liquidation
     * If a user goes below 1, they can get liquidated
     * @param user address of user
     */
    function _healthFactor(address user) private view returns(uint) {
        (uint totalDscMinted, uint usdCollateralValue) = _getAccountInfo(user);
        uint collateralAdjustedForThreshold = (usdCollateralValue * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _getAccountInfo(address user) private view returns(uint totalDscMinted, uint usdCollateralValue) {
        totalDscMinted = s_amountDSCMinted[user];
        usdCollateralValue = getAccountCollateralValue(user);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    ////////////////////////////////////////
    // Public and External View functions //
    ////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns(uint usdCollateralValue) {
        for (uint i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint amount = s_collateralDeposited[user][token];
            usdCollateralValue += getUsdValue(token, amount);
        }
        return usdCollateralValue;
    }

    function getUsdValue(address token, uint amount) public view returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int price,,,) = priceFeed.latestRoundData();
        return (uint(price) * ADDITIONAL_FEED_PRECISION) * amount / PRECISION;
    }

}