pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IPriceEstimator.sol";

contract PriceEstimator is IPriceEstimator, Initializable, OwnableUpgradeSafe {
  using Address for address;

  //address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;

  IUniswapV2Router02 internal uniswapRouter;

  modifier onlyContract(address account)
  {
    require(account.isContract(), "[Validation] The address does not contain a contract");
    _;
  }

  function initialize(address uniswapRouterAddress)
  external
  onlyContract(uniswapRouterAddress)
  {
    __PriceEstimator_init(uniswapRouterAddress);
  }

  function __PriceEstimator_init(address uniswapRouterAddress)
  internal
  initializer
  {
    __Context_init_unchained();
    __Ownable_init_unchained();
    uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
  }

  function setUniswapRouter(address uniswapRouterAddress)
  external
  onlyOwner
  onlyContract(uniswapRouterAddress)
  {
    require(
      uniswapRouterAddress != address(0),
      "[Validation]: Invalid uniswap router address"
    );
    uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
  }

  function getEstimatedETHforERC20(uint256 erc20Amount, address tokenAddress)
  external
  override
  view
  returns (uint256[] memory)
  {
    return uniswapRouter.getAmountsIn(erc20Amount, getPathForETHtoERC20(tokenAddress));
  }

  function getPathForETHtoERC20(address tokenAddress)
  internal
  view
  returns (address[] memory)
  {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = tokenAddress;
    return path;
  }

  function getEstimatedERC20forETH(uint256 etherAmount, address tokenAddress)
  external
  override
  view
  returns (uint256[] memory)
  {
    return uniswapRouter.getAmountsIn(etherAmount, getPathForERC20toETH(tokenAddress));
  }

  function getPathForERC20toETH(address tokenAddress)
  internal
  view
  returns (address[] memory)
  {
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = uniswapRouter.WETH();
    return path;
  }
}