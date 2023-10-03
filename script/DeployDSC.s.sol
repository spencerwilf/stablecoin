// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract DeployDSC is Script {


    function run() external returns(StableCoin, DSCEngine) {
        vm.startBroadcast();
        new StableCoin();
        new DSCEngine();
        vm.stopBroadcast();
    }
}