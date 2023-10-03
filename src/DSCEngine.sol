// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {StableCoin} from "./StableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    error DSCEngine__LessThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TokenTransferFailed();


    ////////////////////////
    // State variables /////
    /////////////////////// 

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint amount)) private s_collateralDeposited;

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

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}