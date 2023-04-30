// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import {TradingCenter, IERC20} from "../src/TradingCenter.sol";
import {TradingCenterV2} from "../src/TradingCenterV2.sol";
import {UpgradeableProxy} from "../src/UpgradeableProxy.sol";

contract FiatToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}
}

contract TradingCenterTest is Test {
    // Owner and users
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    // Contracts
    TradingCenter tradingCenter;
    TradingCenterV2 tradingCenterV2;
    TradingCenter proxyTradingCenter;
    UpgradeableProxy proxy;
    IERC20 usdt;
    IERC20 usdc;

    // Initial balances
    uint256 initialBalance = 100000 ether;
    uint256 userInitialBalance = 10000 ether;

    function setUp() public {
        vm.startPrank(owner);
        // 1. Owner deploys TradingCenter
        // 1. Owner depoly TradingCenter 合約
        tradingCenter = new TradingCenter();
        // 2. Owner deploys UpgradeableProxy with TradingCenter address
        // 2.Owner deploy UpgradeableProxy 並在 constructor 傳入剛 deploy tradingCenter 的 address
        proxy = new UpgradeableProxy(address(tradingCenter));
        // 3. Assigns proxy address to have interface of TradingCenter
        // proxyTradingCenter = 有 interface of TradingCenter 的 proxy (能用 TradingCenter 的function)
        // 但 proxyTradingCenter 的 address 仍然等於 proxy ( 因為沒有 depoly 新合約 )
        // 要使用 TradingCenter 內的 function，需使用 proxyTradingCenter
        proxyTradingCenter = TradingCenter(address(proxy));
        // 4. Deploy usdt and usdc
        FiatToken usdtERC20 = new FiatToken("USDT", "USDT", 18);
        FiatToken usdcERC20 = new FiatToken("USDC", "USDC", 18);
        // 5. Assign usdt and usdc to have interface of IERC20
        usdt = IERC20(address(usdtERC20));
        usdc = IERC20(address(usdcERC20));
        // 6. owner initialize on proxyTradingCenter
        proxyTradingCenter.initialize(usdt, usdc);
        vm.stopPrank();

        // Let proxyTradingCenter to have some initial balances of usdt and usdc
        deal(address(usdt), address(proxyTradingCenter), initialBalance);
        deal(address(usdc), address(proxyTradingCenter), initialBalance);

        // 取得 proxyTradingCenter 擁有的 usdt、usdc 值
        // uint256 usdt_v = proxyTradingCenter.usdt().balanceOf(address(proxyTradingCenter));
        // uint256 usdc_v = proxyTradingCenter.usdc().balanceOf(address(proxyTradingCenter));
        // console.log("usdt_v", usdt_v);
        // console.log("usdc_v", usdc_v);

        // Let user1 and user2 to have some initial balances of usdt and usdc
        deal(address(usdt), user1, userInitialBalance);
        deal(address(usdc), user1, userInitialBalance);
        deal(address(usdt), user2, userInitialBalance);
        deal(address(usdc), user2, userInitialBalance);

        // user1 approve to proxyTradingCenter
        vm.startPrank(user1);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();

        // user1 approve to proxyTradingCenter
        vm.startPrank(user2);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();

        // test exchange
        // uint256 usdt_n1 = proxyTradingCenter.usdt().balanceOf(user1);
        // console.log("usdt_n1", usdt_n1);

        // vm.prank(user1);
        // proxyTradingCenter.exchange(usdt, 100);

        // uint256 usdt_n2 = proxyTradingCenter.usdt().balanceOf(user1);
        // console.log("usdt_n2", usdt_n2);

    }

    function testUpgrade() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And check if all state are correct (initialized, usdt address, usdc address)

        Upgrade();

        // test exchange
        // uint256 usdt_n1 = proxyTradingCenter.usdt().balanceOf(user1);
        // console.log("usdt_n1", usdt_n1);

        // vm.prank(user1);
        // proxyTradingCenter.exchange2(usdt, 100);

        // uint256 usdt_n2 = proxyTradingCenter.usdt().balanceOf(user1);
        // console.log("usdt_n2", usdt_n2);

        assertEq(proxyTradingCenter.initialized(), true);
        assertEq(address(proxyTradingCenter.usdc()), address(usdc));
        assertEq(address(proxyTradingCenter.usdt()), address(usdt));
    }

    function testRugPull() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And empty users' usdc and usdt

        Upgrade();

        TradingCenterV2(address(proxy)).rugPullAllAssets(user1, owner);
        TradingCenterV2(address(proxy)).rugPullAllAssets(user2, owner);


        // 確認一下 approve 給 trading center 的扣打還有沒有在
        // uint256 user1_approve_usdt = proxyTradingCenter.usdt().allowance(user1, address(proxyTradingCenter));
        // uint256 user1_approve_usdc = proxyTradingCenter.usdc().allowance(user1, address(proxyTradingCenter));
        // console.log("user1_approve_usdt", user1_approve_usdt);
        // console.log("user1_approve_usdc", user1_approve_usdc);


        // Assert users's balances are 0
        assertEq(usdt.balanceOf(user1), 0);
        assertEq(usdc.balanceOf(user1), 0);
        assertEq(usdt.balanceOf(user2), 0);
        assertEq(usdc.balanceOf(user2), 0);
    }

    function Upgrade() public {
        vm.startPrank(owner);
        // 佈個合約
        tradingCenterV2 = new TradingCenterV2();
        // console.log("tradingCenterV2", address(tradingCenterV2));
        proxy.upgradeTo(address(tradingCenterV2));
        proxyTradingCenter = TradingCenterV2(address(proxy));

        // 確認 implementation 存的值有沒有變成剛佈的合約地址
        // address addr = proxy.implementation();
        // console.log(addr);

        vm.stopPrank();
    }

    // function tryExchange(IERC20 _token, address _user) public {
    //     uint256 v1 = proxyTradingCenter._token().balanceOf(_user);
    //     console.log("v1", v1);

    //     vm.prank(_user);
    //     proxyTradingCenter.exchange(_token, 100);

    //     uint256 v2 = proxyTradingCenter._token().balanceOf(_user);
    //     console.log("v2", v2);
    // }
}
