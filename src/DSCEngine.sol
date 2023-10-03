// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;


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
contract DSCEngine {

    ////////////////
    // Errors /////
    ///////////////

    error DSCEngine__LessThanZero();
    

    ////////////////
    // Modifiers //
    ///////////////

    modifier moreThanZero(uint amount) {
        if (amount <= 0) {
            revert DSCEngine__LessThanZero();
        }
        _;
    }

    function depositCollateralAndMintDSC() external {}

    /**
     * 
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral  The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint amountCollateral) external moreThanZero(amountCollateral) {}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}