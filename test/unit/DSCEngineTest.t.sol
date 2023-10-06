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
    address wbtcUsdPriceFeed;
    address wbtc;


    address public user = makeAddr("user");
    uint public constant AMOUNT_COLLATERAL = 10 ether;
    uint public constant STARTING_ERC_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (stableCoin, engine, config) = deployer.run();
        (ethUsdPriceFeed,wbtcUsdPriceFeed,weth,wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_ERC_BALANCE);
    }

    ///////////////////////
    // Constructor Tests //
    ////////////////////// 

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeed() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(stableCoin));
    }

    function testTokenAmountFromUSD() public {
        uint usdAmount = 100 ether;
        uint expectedWeth = 0.05 ether;

        uint actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
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

    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock newToken = new ERC20Mock();
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(newToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint totalDscMinted, uint collateralValue) = engine.getAccountInformation(user);

        uint expectedTotalDscMinted = 0;
        uint expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValue);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);

    }
}