
// SPDX-License-Identifier: GPL-3.0


/**

    HOW TO USE

    Convert Ether to Token
    
    1. Calculate amountOut (how much token to receive) using getEstimatedTokenforETH() 
       for X amount of ETH
    2. Specify to (receiver)
    3. Specify order valid time in seconds
    4. Send X amount of ether (better to send x*1.1 amount to avoid trade revert) 


    Convert Token to Ether

    1. Specify amountIn (amount of sending token)
    2. Calculate amountOutMin using getEstimatedTokenforETH(amountIn). This gets the minimum 
       ether you want back. For a confirm trade its better to pass in (amountOutMin * 0.9)
       from frontend.
    3. Specify to and valid_upto_seconds

    * IMPORTANT - to in both functions depends on usecase. to can be a normal address or in some
      case it can also be the contract address itself. 


    LIQUIDITY
    https://rinkeby.etherscan.io/tx/0xbf0fdb331641117ad179f4117ad1392838a26ada80051cb5b3eb57fe49f3149e  

*/

pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract EthUsdaoUniV2 {

  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;

  IUniswapV2Router02 public uniswapRouter;
  
  //address private USDAO Rinkeby = 0x585fcE75fC4F4cC2943AAD3B7726962190441bA1;
  IERC20 ercToken;

  constructor(address _ercTokenAddress) {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    ercToken = IERC20(_ercTokenAddress);
  }

  function convertEthToToken(uint amountOut, address to, uint valid_upto_seconds) public payable {
    //uint deadline = block.timestamp + valid_upto_seconds;; // using 'now' for convenience, for mainnet pass deadline from frontend!
    
    uint deadline = block.timestamp + valid_upto_seconds;
    uniswapRouter.swapETHForExactTokens{ value: msg.value }(amountOut, getPathForETHtoToken(), to, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function convertTokenToEth(uint amountIn, uint amountOutMin, address to, uint valid_upto_seconds) public payable 
    returns (uint[] memory amounts) 
  {
    // amountOutMin must be retrieved from an oracle of some kind
    IERC20 token = IERC20(ercToken);
    // This contract must have enough token balance to send
    require(token.balanceOf(address(this))>=amountIn, "token balance not enough for swap to ether");
    require(token.approve(address(uniswapRouter),0),'approve failed');
    require(token.approve(address(uniswapRouter),amountIn),'approve failed');
    uint deadline = block.timestamp + valid_upto_seconds;
    uint[] memory output_amounts = uniswapRouter.swapExactTokensForETH(amountIn, amountOutMin, getPathForTokentoETH(), to, deadline);      
    return output_amounts;
  }
  
  function getMinOutputforInput(uint tokenAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(tokenAmount, getPathForETHtoToken());
  }
  
  function getMaxOutputForInput(uint EthAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(EthAmount, getPathForTokentoETH());
  }

  function getPathForETHtoToken() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = address(ercToken);
    
    return path;
  }
  
  function getPathForTokentoETH() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = address(ercToken);
    path[1] = uniswapRouter.WETH();
    
    return path;
  }

  function tokenBalanceOf(address account) public view returns(uint256) {
      return IERC20(ercToken).balanceOf(account);
  }

  function etherBalanceOf() public view returns(uint256) {
      return address(this).balance;
  } 
  
  // important to receive ETH
  receive() payable external {}
}