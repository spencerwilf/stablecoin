// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title StableCoin
* @author Spencer Wilfahrt
* Collateral: Exogenous (wETH & BTC)
* Minting: Algorithmic
* Relative stability: Pegged to USD
*
* Contract is meant to be governed by DSCEngine. This contract is the ERC20 implementation of the stablecoin system.
*/
contract StableCoin is ERC20Burnable, Ownable {
    error StableCoin__MustBeGreaterThanZero();
    error StableCoin__BurnAmountExceedsBalance();
    error StableCoin__NotZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert StableCoin__MustBeGreaterThanZero();
        }
        if (balance < _amount) {
            revert StableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert StableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert StableCoin__MustBeGreaterThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
