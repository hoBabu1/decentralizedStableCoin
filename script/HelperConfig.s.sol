//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wEthUsdPriceFeed;
        address wBtcUsdPriceFeed;
        address wETH;
        address wBTC;
        uint256 deployerKey;
    }

    uint8 public constant DECIMAL = 8;
    int256 public constant ETH_USD_PRICE = 1000e18;
    int256 public constant BTC_USD_PRICE = 2000e18;
    uint256 private constant PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;
    //

    constructor() {
        if (block.chainid == 31337) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilNetworkConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaConfig) {
        sepoliaConfig = NetworkConfig({
            wEthUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wBtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wETH: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wBTC: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        return sepoliaConfig;
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMAL, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMAL, BTC_USD_PRICE);
        ERC20Mock btcMock = new ERC20Mock();
        vm.stopBroadcast();
        console.log(address(wethMock));
        console.log(address(btcMock));

        return NetworkConfig({
            wEthUsdPriceFeed: address(ethUsdPriceFeed),
            wBtcUsdPriceFeed: address(btcUsdPriceFeed),
            wETH: address(wethMock),
            wBTC: address(btcMock),
            deployerKey: PRIVATE_KEY
        });
    }
}
