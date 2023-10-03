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

    function depositCollateralAndMintDSC() external {}

    function depositCollateral() external {}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}