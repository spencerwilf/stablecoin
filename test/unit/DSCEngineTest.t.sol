// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {StableCoin} from "../../src/StableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {

    DeployDSC deployer;
    StableCoin stableCoin;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;

    address public user = makeAddr("user");
    uint public constant AMOUNT_COLLATERAL = 10 ether;
    uint public constant STARTING_ERC_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (stableCoin, engine, config) = deployer.run();
        (ethUsdPriceFeed,,weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_ERC_BALANCE);
    }

    //////////////////
    // Price Tests //
    /////////////////

    function testGetUsdValue() public {
        uint ethAmount = 15e18;
        uint expectedUsd = 30000e18;
        uint actualUsd = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }


    //////////////////////////////
    // Deposit Collateral Tests //
    /////////////////////////////

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__LessThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}