pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "./IERC20Extended.sol";
import "./IPriceEstimator.sol";

contract SmartSwap is Initializable, OwnableUpgradeSafe, PausableUpgradeSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    enum Status {
        OPEN,
        CLOSED,
        CANCELLED
    }

    enum SwapType {
        ETH_TO_ERC20,
        ERC20_TO_ETH,
        ERC20_TO_ERC20
    }

    struct Swap {
        uint256 openValue;
        uint256 closeValue;
        address payable openTrader;
        address payable closeTrader;
        address openContractAddress;
        address closeContractAddress;
        SwapType swapType;
        Status status;
    }

    address constant private ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    uint256 constant private DEV_FEE_PERCENTAGE = 10;
    uint256 constant private BURN_FEE_PERCENTAGE = 10;

    //Global swap id. Also give total number of swaps made so far
    uint256 private _swapId;

    mapping (uint256 => Swap) private _swaps;

    IERC20 private _swapToken;

    //Wallet where fees will go
    address payable private _feesWallet;

    //Wallet where dev fund will go
    address private _devWallet;

    uint256 private _ethFeePercentage;
    uint256 private _allowedFeeSlippagePercentage;
    uint256 private _uniswapFeePercentage;

    IPriceEstimator private _priceEstimator;

    //list of free tokens
    mapping(address => bool) private _listFreeTokens;

    event Open(uint256 indexed id, address indexed openTrader, address indexed closeTrader);
    event Cancel(uint256 indexed id);
    event Close(uint256 indexed id);
    event FeeWalletChanged(address indexed wallet);
    event DevWalletChanged(address indexed wallet);
    event SwapTokenUpdated(address indexed swapTokenAddress);

    modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    modifier onlyOpenSwaps(uint256 id) {
        Swap memory swap = _swaps[id];
        require (swap.status == Status.OPEN);
        _;
    }

    /**
    * @dev initialize
    */
    function initialize(
        address swapTokenAddress,
        address payable feesWallet,
        address devWallet,
        address priceEstimator
    )
    external
    onlyContract(swapTokenAddress)
    onlyContract(priceEstimator)
    {
        __SmartSwap_init(swapTokenAddress, feesWallet, devWallet, priceEstimator);
    }

    function __SmartSwap_init(
        address swapTokenAddress,
        address payable feesWallet,
        address devWallet,
        address priceEstimator
    )
    internal
    initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __SmartSwap_init_unchained(swapTokenAddress, feesWallet, devWallet, priceEstimator);
    }

    function __SmartSwap_init_unchained(
        address swapTokenAddress,
        address payable feesWallet,
        address devWallet,
        address priceEstimator
    )
    internal
    initializer
    {
        require(
            swapTokenAddress != address(0),
            "[Validation] Invalid swap token address"
        );
        require(feesWallet != address(0), "[Validation] feesWallet is the zero address");
        require(devWallet != address(0), "[Validation] devWallet is the zero address");
        require(
            priceEstimator != address(0),
            "[Validation] Invalid price estimator address"
        );

        _swapToken = IERC20(swapTokenAddress);
        _feesWallet = feesWallet;
        _devWallet = devWallet;
        _priceEstimator = IPriceEstimator(priceEstimator);
        _ethFeePercentage = 3;
        _allowedFeeSlippagePercentage = 5;
        _uniswapFeePercentage = 3;
    }

    /**
    * @dev Called by an admin to pause, triggers stopped state.
    */
    function pause()
    external
    onlyOwner 
    {
        _pause();
    }

    /**
    * @dev Called by an admin to unpause, returns to normal state.
    */
    function unpause()
    external
    onlyOwner
    {
        _unpause();
    }

    /**
    * @dev Update swap token address
    * @param swapTokenAddress New swap token address
    */
    function setSwapToken(address swapTokenAddress)
    external
    onlyOwner
    onlyContract(swapTokenAddress)
    {
        require(
            swapTokenAddress != address(0),
            "[Validation]: Invalid swap token address"
        );
        _swapToken = IERC20(swapTokenAddress);
        emit SwapTokenUpdated(swapTokenAddress);
    }

    /**
    * @dev Allows admin to set fee receiver wallet
    * @param wallet New wallet address
    */
    function setFeeWallet(address payable wallet)
    external
    onlyOwner
    {
        require(
            wallet != address(0),
            "[Validation] feesWallet is the zero address"
        );
        _feesWallet = wallet;

        emit FeeWalletChanged(wallet);
    }

    /**
    * @dev Allows admin to set fee receiver wallet
    * @param wallet New wallet address
    */
    function setDevWallet(address payable wallet)
    external
    onlyOwner
    {
        require(
            wallet != address(0),
            "[Validation] devWallet is the zero address"
        );
        _devWallet = wallet;

        emit DevWalletChanged(wallet);
    }

    /**
    * @dev Update price estimator address
    * @param priceEstimator New price estimator address
    */
    function setPriceEstimator(address priceEstimator)
    external
    onlyOwner
    onlyContract(priceEstimator)
    {
        require(
            priceEstimator != address(0),
            "[Validation]: Invalid price estimator address"
        );
        _priceEstimator = IPriceEstimator(priceEstimator);
    }

    /**
    * @dev Update fees
    * @param ethFeePercentage New percentage of fee in eth
    */
    function setEthFeePercentage(uint8 ethFeePercentage)
    external
    onlyOwner
    {
        require(
            ethFeePercentage >= 0 && ethFeePercentage <= 100,
            "[Validation]: ETH Fee percentage must be between 0 to 100"
        );
        _ethFeePercentage = ethFeePercentage;
    }

    /**
    * @dev Update fee slippage percentage allowance for erc20
    * @param allowedFeeSlippagePercentage New allowed fee slippage percentage for fee in erc20
    */
    function setAllowedFeeSlippagePercentage(uint8 allowedFeeSlippagePercentage)
    external
    onlyOwner
    {
        require(
            allowedFeeSlippagePercentage >= 0 && allowedFeeSlippagePercentage <= 100,
            "[Validation]: Allowed Fee Slippage percentage must be between 0 to 100"
        );
        _allowedFeeSlippagePercentage = allowedFeeSlippagePercentage;
    }

    /**
    * @dev Update Uniswap fees
    * @param uniswapFeePercentage New percentage of uniswap fee
    */
    function setUniswapFeePercentage(uint8 uniswapFeePercentage)
    external
    onlyOwner
    {
        require(
            uniswapFeePercentage >= 0 && uniswapFeePercentage <= 100,
            "[Validation]: Uniswap Fee percentage must be between 0 to 100"
        );
        _uniswapFeePercentage = uniswapFeePercentage;
    }

    function getFeeInEthForEth(uint256 amount)
    public
    view
    returns (uint256) 
    {
        //_ethFeePercentage is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
        return amount.mul(_ethFeePercentage).div(1000); //0.3% of ETH amount
    }

    function getFeeInEthForERC20(uint256 amount, address token)
    public 
    view
    returns (uint256)
    {
        if(isFreeToken(token)) {
            return 0;
        } else {
            //price should be estimated by 1 token because Uniswap algo changes price based on large amount
            uint256 tokenBits = 10 ** uint256(IERC20Extended(token).decimals());
            uint256 estFeesInEthPerUnit = _priceEstimator.getEstimatedETHforERC20(tokenBits, token)[0];
            //subtract uniswap 0.30% fees
            //_uniswapFeePercentage is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
            estFeesInEthPerUnit = estFeesInEthPerUnit.sub(estFeesInEthPerUnit.mul(_uniswapFeePercentage).div(1000));
            uint256 equivEth = amount.mul(estFeesInEthPerUnit).div(tokenBits); //multiply by amount to be scheduled amount
            return getFeeInEthForEth(equivEth);
        }
    }

    function getFeeInEthForERC20UsingTotalSupply(uint256 amount, address token)
    public
    view
    returns (uint256)
    {
        if(isFreeToken(token)) {
            return 0;
        } else {
            //per 1% supply , 0.1 ETH is the fee
            uint256 tokenTotalSupply = IERC20(token).totalSupply();
            uint256 percentage = amount.mul(tokenTotalSupply).mul(100).div(tokenTotalSupply);
            uint256 ethFeeInWei = 100000000000000000; //0.1 ETH
            return percentage.mul(ethFeeInWei).div(tokenTotalSupply);
        }
    }

    function getFeeInSwapForETH(uint256 amount)
    public
    view
    returns (uint256)
    {
        uint256 feesInEth = getFeeInEthForEth(amount);
        return _getEquivSwapFee(feesInEth);
    }

    function getFeeInSwapForERC20(uint256 amount, address token, bool calcFeeUsingTotalSupply)
    public
    view
    returns (uint256)
    {
        uint256 feesInEth = calcFeeUsingTotalSupply ? 
            getFeeInEthForERC20UsingTotalSupply(amount, token) : 
            getFeeInEthForERC20(amount, token);
        return _getEquivSwapFee(feesInEth);
    }

    function _getEquivSwapFee(uint256 feesInEth)
    private
    view
    returns (uint256)
    {
        uint256 feesInEthIfPaidViaSwap = feesInEth.div(2);
        uint256 swapPerEth = _priceEstimator.getEstimatedERC20forETH(1, address(_swapToken))[0];
        //subtract uniswap 0.30% fees
        //_uniswapFeePercentage is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
        uint256 estSwapPerEth = swapPerEth.sub(swapPerEth.mul(_uniswapFeePercentage).div(1000));
        return feesInEthIfPaidViaSwap.mul(estSwapPerEth);
    }

    function _distributeFees(uint256 fee)
    private
    {
        uint256 devAmount = fee.mul(DEV_FEE_PERCENTAGE).div(100); //10%
        uint256 burnAmount = fee.mul(BURN_FEE_PERCENTAGE).div(100); //10%
        uint256 remAmount = fee.sub(devAmount).sub(burnAmount); //80%

        _swapToken.safeTransferFrom(msg.sender, _feesWallet, remAmount);
        _swapToken.safeTransferFrom(msg.sender, _devWallet, devAmount);
        IERC20Extended(address(_swapToken)).burnFrom(msg.sender, burnAmount);
    }

    function open(
        uint256 openValue,
        address openContractAddress,
        uint256 closeValue,
        address payable closeTrader,
        address closeContractAddress,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    external
    payable
    whenNotPaused
    {
        require(openValue > 0, "[Validation] The open value has to be larger than 0");
        require(closeValue > 0, "[Validation] The close value has to be larger than 0");
        if(!isFreeToken(openContractAddress)) {
        require(fee > 0, "[Validation] The fee has to be larger than 0");
        }
        require(closeTrader != address(0), "[Validation] Invalid close trader address");

        if(ETH_ADDRESS == openContractAddress)
        {
            _openEtherToERC20(
                openValue,
                closeValue,
                closeTrader,
                closeContractAddress,
                fee,
                isFeeInSwap
            );
        } 
        else if(ETH_ADDRESS == closeContractAddress)
        {
            _openERC20ToEther(
                openValue,
                openContractAddress,
                closeTrader,
                closeValue,
                fee,
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );
        }
        else
        {
            _openERC20ToERC20(
                openValue,
                openContractAddress,
                closeValue,
                closeTrader,
                closeContractAddress,
                fee,
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );
        }
    }

    function _openEtherToERC20(
        uint256 ethValue,
        uint256 erc20Value,
        address payable erc20Trader,
        address erc20ContractAddress,
        uint256 fee,
        bool isFeeInSwap
    )
    private
    whenNotPaused
    onlyContract(erc20ContractAddress)
    {
        require(ethValue > 0, "[Validation] The ETH amount has to be larger than 0");
        require(erc20Value > 0, "[Validation] The ERC-20 amount has to be larger than 0");
        require(fee > 0, "[Validation] The fee has to be larger than 0");

        //Transferring fee to the wallet
        if(isFeeInSwap){
            require(msg.value >= ethValue, "[Validation] Enough ETH not sent");
            uint256 minRequiredFeeInSwap = getFeeInSwapForETH(ethValue);
            uint256 feeDiff = 0;
            if( fee < minRequiredFeeInSwap ) {
                feeDiff = minRequiredFeeInSwap.sub(fee);
                uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                //will allow if diff is less than 5%
                require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
            }
            _distributeFees(minRequiredFeeInSwap);
        }
        else {
            uint256 minRequiredFeeInEth = getFeeInEthForEth(ethValue);
            require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
            require(msg.value >= ethValue.add(minRequiredFeeInEth), "[Validation] Enough ETH not sent");
            (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
            require(success, "[Validation] Transfer of fee failed");
        }

        _swapId = _swapId.add(1);

        // Store the details of the swap.
        _swaps[_swapId] = Swap({
            openValue: ethValue,
            openTrader: msg.sender,
            openContractAddress: ETH_ADDRESS,
            closeValue: erc20Value,
            closeTrader: erc20Trader,
            closeContractAddress: erc20ContractAddress,
            swapType: SwapType.ETH_TO_ERC20,
            status: Status.OPEN
        });

        emit Open(_swapId, msg.sender, erc20Trader);
    }

    function _openERC20ToEther(
        uint256 erc20Value,
        address erc20ContractAddress,
        address payable ethTrader,
        uint256 ethValue,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    whenNotPaused
    onlyContract(erc20ContractAddress)
    {
        require(ethValue > 0, "[Validation] The ETH amount has to be larger than 0");
        require(erc20Value > 0, "[Validation] The ERC-20 amount has to be larger than 0");
        
        if(!isFreeToken(erc20ContractAddress)) {
            //Transfer fee to the wallet
            if(isFeeInSwap){
                uint256 minRequiredFeeInSwap = getFeeInSwapForERC20(erc20Value, erc20ContractAddress, calcFeeUsingTotalSupply);
                uint256 feeDiff = 0;
                if( fee < minRequiredFeeInSwap ) {
                    feeDiff = minRequiredFeeInSwap.sub(fee);
                    uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                    //will allow if diff is less than 5%
                    require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
                }
                _distributeFees(minRequiredFeeInSwap);
            }
            else {
                uint256 minRequiredFeeInEth = calcFeeUsingTotalSupply ? 
                    getFeeInEthForERC20UsingTotalSupply(erc20Value, erc20ContractAddress) : 
                    getFeeInEthForERC20(erc20Value, erc20ContractAddress);
                require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
                require(msg.value >= minRequiredFeeInEth, "[Validation] msg.value doesn't contain enough ETH for fee");
                (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
                require(success, "[Validation] Transfer of fee failed");
            }
        }
        // Transfer value from the opening trader to this contract.
        IERC20 openERC20Contract = IERC20(erc20ContractAddress);
        require(erc20Value <= openERC20Contract.allowance(msg.sender, address(this)));
        require(openERC20Contract.transferFrom(msg.sender, address(this), erc20Value));

        _swapId = _swapId.add(1);

        // Store the details of the swap.
        _swaps[_swapId] = Swap({
            openValue: erc20Value,
            openTrader: msg.sender,
            openContractAddress: erc20ContractAddress,
            closeValue: ethValue,
            closeTrader: ethTrader,
            closeContractAddress: ETH_ADDRESS,
            swapType: SwapType.ERC20_TO_ETH,
            status: Status.OPEN
        });

        emit Open(_swapId, msg.sender, ethTrader);
    }

    function _openERC20ToERC20(
        uint256 openValue,
        address openContractAddress,
        uint256 closeValue,
        address payable closeTrader,
        address closeContractAddress,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    whenNotPaused
    {
        require(openValue > 0, "[Validation] The open ERC-20 amount has to be larger than 0");
        require(closeValue > 0, "[Validation] The close ERC-20 amount has to be larger than 0");
        
        if(!isFreeToken(openContractAddress)) {
            //Transfer fee to the wallet
            if(isFeeInSwap){
                uint256 minRequiredFeeInSwap = getFeeInSwapForERC20(openValue, openContractAddress, calcFeeUsingTotalSupply);
                uint256 feeDiff = 0;
                if( fee < minRequiredFeeInSwap ) {
                    feeDiff = minRequiredFeeInSwap.sub(fee);
                    uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                    //will allow if diff is less than 5%
                    require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
                }
                _distributeFees(minRequiredFeeInSwap);
            }
            else {
                uint256 minRequiredFeeInEth = calcFeeUsingTotalSupply ? 
                    getFeeInEthForERC20UsingTotalSupply(openValue, openContractAddress) : 
                    getFeeInEthForERC20(openValue, openContractAddress);
                require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
                require(msg.value >= minRequiredFeeInEth, "[Validation] msg.value doesn't contain enough ETH for fee");
                (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
                require(success, "[Validation] Transfer of fee failed");
            }
        }

        // Transfer value from the opening trader to this contract.
        IERC20 openERC20Contract = IERC20(openContractAddress);
        require(openValue <= openERC20Contract.allowance(msg.sender, address(this)));
        require(openERC20Contract.transferFrom(msg.sender, address(this), openValue));

        _swapId = _swapId.add(1);

        // Store the details of the swap.
        _swaps[_swapId] = Swap({
            openValue: openValue,
            openTrader: msg.sender,
            openContractAddress: openContractAddress,
            closeValue: closeValue,
            closeTrader: closeTrader,
            closeContractAddress: closeContractAddress,
            swapType: SwapType.ERC20_TO_ERC20,
            status: Status.OPEN
        });

        emit Open(_swapId, msg.sender, closeTrader);
    }

    function close(
        uint256 id,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    external
    payable
    onlyOpenSwaps(id)
    {
        Swap memory swap = _swaps[id];
        require(swap.closeTrader == _msgSender(), "[Validation]: The caller is not authorized to close the trade");
        if(SwapType.ETH_TO_ERC20 == swap.swapType)
        {
            _closeEtherToERC20(
                id,
                fee,
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );
        } 
        else if(SwapType.ERC20_TO_ETH == swap.swapType)
        {
            _closeERC20ToEther(
                id,
                fee,
                isFeeInSwap
            );
        }
        else
        {
            _closeERC20ToERC20(
                id,
                fee,
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );
        }
    }

    function _closeEtherToERC20(
        uint256 id,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    onlyOpenSwaps(id)
    {
        Swap storage swap = _swaps[id];

        if(!isFreeToken(swap.closeContractAddress)) {
            //Transfer fee to the wallet
            if(isFeeInSwap){
                uint256 minRequiredFeeInSwap = getFeeInSwapForERC20(swap.closeValue, swap.closeContractAddress, calcFeeUsingTotalSupply);
                uint256 feeDiff = 0;
                if( fee < minRequiredFeeInSwap ) {
                    feeDiff = minRequiredFeeInSwap.sub(fee);
                    uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                    //will allow if diff is less than 5%
                    require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
                }
                _distributeFees(minRequiredFeeInSwap);
            }
            else {
                uint256 minRequiredFeeInEth = calcFeeUsingTotalSupply ? 
                    getFeeInEthForERC20UsingTotalSupply(swap.closeValue, swap.closeContractAddress) : 
                    getFeeInEthForERC20(swap.closeValue, swap.closeContractAddress);
                require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
                require(msg.value >= minRequiredFeeInEth, "[Validation] msg.value doesn't contain enough ETH for fee");
                (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
                require(success, "[Validation] Transfer of fee failed");
            }
        }
        // Close the swap.
        swap.status = Status.CLOSED;

        // Transfer the ERC20 funds from the ERC20 trader to the ETH trader.
        IERC20 erc20Contract = IERC20(swap.closeContractAddress);
        require(swap.closeValue <= erc20Contract.allowance(swap.closeTrader, address(this)));
        require(erc20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

        // Transfer the ETH funds from this contract to the ERC20 trader.
        swap.closeTrader.transfer(swap.openValue);
        
        emit Close(id);
    }

    function _closeERC20ToEther(
        uint256 id,
        uint256 fee,
        bool isFeeInSwap
    )
    private
    onlyOpenSwaps(id)
    {
        Swap storage swap = _swaps[id];

        //Transferring fee to the wallet
        if(isFeeInSwap){
            require(msg.value >= swap.closeValue, "[Validation] Enough ETH not sent");
            uint256 minRequiredFeeInSwap = getFeeInSwapForETH(swap.closeValue);
            uint256 feeDiff = 0;
            if( fee < minRequiredFeeInSwap ) {
                feeDiff = minRequiredFeeInSwap.sub(fee);
                uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                //will allow if diff is less than 5%
                require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
            }
            _distributeFees(minRequiredFeeInSwap);
        }
        else {
            uint256 minRequiredFeeInEth = getFeeInEthForEth(swap.closeValue);
            require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
            require(msg.value >= swap.closeValue.add(minRequiredFeeInEth), "[Validation] Enough ETH not sent");
            (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
            require(success, "[Validation] Transfer of fee failed");
        }

        // Close the swap.
        swap.status = Status.CLOSED;

        // Transfer the opening funds from this contract to the eth trader.
        IERC20 openERC20Contract = IERC20(swap.openContractAddress);
        require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

        (bool success,) = swap.openTrader.call.value(swap.closeValue)("");
        require(success, "[Validation] Transfer of eth failed");
        
        emit Close(id);
    }

    function _closeERC20ToERC20(
        uint256 id,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    onlyOpenSwaps(id)
    {
        Swap storage swap = _swaps[id];

        if(!isFreeToken(swap.closeContractAddress)) {
            //Transfer fee to the wallet
            if(isFeeInSwap){
                uint256 minRequiredFeeInSwap = getFeeInSwapForERC20(swap.closeValue, swap.closeContractAddress, calcFeeUsingTotalSupply);
                uint256 feeDiff = 0;
                if( fee < minRequiredFeeInSwap ) {
                    feeDiff = minRequiredFeeInSwap.sub(fee);
                    uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInSwap);
                    //will allow if diff is less than 5%
                    require(feeSlippagePercentage < _allowedFeeSlippagePercentage, "[Validation] Fee (SWAP) is below minimum required fee");
                }
                _distributeFees(minRequiredFeeInSwap);
            }
            else {
                uint256 minRequiredFeeInEth = calcFeeUsingTotalSupply ? 
                    getFeeInEthForERC20UsingTotalSupply(swap.closeValue, swap.closeContractAddress) : 
                    getFeeInEthForERC20(swap.closeValue, swap.closeContractAddress);
                require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
                require(msg.value >= minRequiredFeeInEth, "[Validation] msg.value doesn't contain enough ETH for fee");
                (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
                require(success, "[Validation] Transfer of fee failed");
            }
        }

        // Close the swap.
        swap.status = Status.CLOSED;

        // Transfer the closing funds from the closing trader to the opening trader.
        IERC20 closeERC20Contract = IERC20(swap.closeContractAddress);
        require(swap.closeValue <= closeERC20Contract.allowance(swap.closeTrader, address(this)));
        require(closeERC20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

        // Transfer the opening funds from this contract to the closing trader.
        IERC20 openERC20Contract = IERC20(swap.openContractAddress);
        require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

        emit Close(id);
    }

    function cancel(uint256 id)
    external
    onlyOpenSwaps(id)
    {
        Swap memory swap = _swaps[id];
        require(swap.openTrader == _msgSender(), "[Validation]: The caller is not authorized to cancel the trade");
        if(SwapType.ETH_TO_ERC20 == swap.swapType) {
            _cancelEtherToERC20(id);
        }
        else {
            _cancelERC20(id);
        }
    }

    function _cancelEtherToERC20(uint256 id)
    private
    onlyOpenSwaps(id)
    {
        // Cancel the swap.
        Swap storage swap = _swaps[id];
        swap.status = Status.CANCELLED;

        // Transfer the ETH value from this contract back to the ETH trader.
        swap.openTrader.transfer(swap.openValue);
        emit Cancel(id);
    }

    function _cancelERC20(uint256 id)
    private
    onlyOpenSwaps(id)
    {
        // Cancel the swap.
        Swap storage swap = _swaps[id];
        swap.status = Status.CANCELLED;

        // Transfer opening value from this contract back to the opening trader.
        IERC20 openERC20Contract = IERC20(swap.openContractAddress);
        require(openERC20Contract.transfer(swap.openTrader, swap.openValue));

        emit Cancel(id);
    }

    function check(uint256 id)
    external
    view
    returns (
        uint256 openValue,
        address openTrader,
        address openContractAddress,
        uint256 closeValue,
        address closeTrader,
        address closeContractAddress,
        SwapType swapType,
        Status status
    )
    {
        Swap memory swap = _swaps[id];
        return (
            swap.openValue, 
            swap.openTrader, 
            swap.openContractAddress, 
            swap.closeValue, 
            swap.closeTrader, 
            swap.closeContractAddress,
            swap.swapType,
            swap.status
        );
    }

    /**
    * @dev called by admin to add given token to free tokens list
    */
    function addTokenToFreeList(address token)
    external
    onlyOwner
    onlyContract(token)
    {
        _listFreeTokens[token] = true;
    }

    /**
    * @dev called by admin to remove given token from free tokens list
    */
    function removeTokenFromFreeList(address token)
    external
    onlyOwner
    onlyContract(token)
    {
        _listFreeTokens[token] = false;
    }

    /**
    * @dev Checks if token is in free list
    * @param token The address to check
    */
    function isFreeToken(address token)
    public
    view
    returns(bool)
    {
        return _listFreeTokens[token];
    }
}