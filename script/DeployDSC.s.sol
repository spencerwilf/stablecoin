// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;


    function run() external returns(StableCoin, DSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed,
        address wbtcUsdPriceFeed,
        address weth,
        address wbtc,
        uint256 deployerKey
        ) = config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        StableCoin stableCoin = new StableCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(stableCoin));

        stableCoin.transferOwnership(address(engine));
        vm.stopBroadcast();

        return (stableCoin, engine, config);
    }
}