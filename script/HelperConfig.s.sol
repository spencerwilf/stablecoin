// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
        address wethUSDPriceFeed;
        address wbtcUSDPriceFeed;
        address wethAddress;
        address wbtcAddress;
        uint deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {}

    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
            wethUSDPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUSDPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wethAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            wbtcAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}