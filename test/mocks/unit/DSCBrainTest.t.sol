//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {Test,console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDsc.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

import {DSCBrain} from "src/DSCBrain.sol";

contract DSCBrainTest is Test {
    DeployDSC dscDeployer;
    DSCBrain dscBrain;
    HelperConfig helperConfig;
    DecentralizedStableCoin dscCoin;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    function setUp() external {
        dscDeployer = new DeployDSC();
        (dscCoin, dscBrain, helperConfig) = dscDeployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
    }
    function testgetValueinUsd() public  {
        uint256 a = 6;
        uint256 b = 6;
        dscBrain.getValueinUsd(weth,5e18);
        assert(a==b);
    }
}
