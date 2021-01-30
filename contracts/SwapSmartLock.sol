pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./IERC20Extended.sol";
import "./IPriceEstimator.sol";

/**
* @dev This contract will hold user scheduled payments which will be released after
* release time
*/
contract SwapSmartLock is Initializable, OwnableUpgradeSafe, PausableUpgradeSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    enum Status { CLOSED, OPEN }

    IERC20 private _swapToken;

    //Wallet where fees will go
    address payable private _feesWallet;

    //Wallet where dev fund will go
    address private _devWallet;

    address constant private ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    uint256 constant private DEV_FEE_PERCENTAGE = 10;
    uint256 constant private BURN_FEE_PERCENTAGE = 10;

    struct Payment {
        address token;// Token address
        address sender;
        address payable beneficiary;// Beneficary who will receive funds
        uint256 amount;
        uint256 releaseTime;
        uint256 createdAt;
        Status status;
    }

    //Global payment id. Also give total number of payments made so far
    uint256 private _paymentId;

    //list of all payment ids for a user/beneficiary
    mapping(address => uint256[]) private _beneficiaryVsPaymentIds;

    //list of all payment ids for a sender
    mapping(address => uint256[]) private _senderVsPaymentIds;

    mapping(uint256 => Payment) private _idVsPayment;

    IPriceEstimator private _priceEstimator;

    uint256 private _ethFeePercentage;
    uint256 private _allowedFeeSlippagePercentage;
    uint256 private _uniswapFeePercentage;

    uint256 private _maxFeeInEth;

    //list of free tokens
    mapping(address => bool) private _listFreeTokens;

    event PaymentScheduled(
        address indexed token,
        address indexed sender,
        address indexed beneficiary,
        uint256 id,
        uint256 amount,
        uint256 releaseTime,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    );

    event PaymentReleased(
        uint256 indexed id,
        address indexed beneficiary,
        address indexed token
    );

    event FeeWalletChanged(address indexed wallet);
    event DevWalletChanged(address indexed wallet);
    event SwapTokenUpdated(address indexed swapTokenAddress);

    modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    modifier canRelease(uint256 id) {
        require(releasable(id), "[Release]: Can't release payment");
        _;
    }

    /**
    * @dev initialize
    * @param swapTokenAddress Address of the swap token
    * @param feesWallet Wallet address where fees will go
    * @param devWallet Wallet address where dev fund will go
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
        __SwapSmartLock_init(swapTokenAddress, feesWallet, devWallet, priceEstimator);
    }

    function __SwapSmartLock_init(
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
        __SwapSmartLock_init_unchained(swapTokenAddress, feesWallet, devWallet, priceEstimator);
    }

    function __SwapSmartLock_init_unchained(
        address swapTokenAddress,
        address payable feesWallet,
        address devWallet,
        address priceEstimator
    )
    internal
    initializer
    {
        require(feesWallet != address(0), "[Validation] feesWallet is the zero address");
        require(devWallet != address(0), "[Validation] devWallet is the zero address");

        _swapToken = IERC20(swapTokenAddress);
        _feesWallet = feesWallet;
        _devWallet = devWallet;
        _priceEstimator = IPriceEstimator(priceEstimator);
        _ethFeePercentage = 1;
        _allowedFeeSlippagePercentage = 5;
        _uniswapFeePercentage = 3;
    }

    /**
    * @dev returns the fee receiver wallet address
    */
    function getFeesWallet()
    external
    view
    returns(address)
    {
        return _feesWallet;
    }

    /**
    * @dev returns the dev fund wallet address
    */
    function getDevWallet()
    external
    view
    returns(address)
    {
        return _devWallet;
    }

    /**
    * @dev Returns swap token address
    */
    function getSwapToken()
    external
    view
    returns(address)
    {
        return address(_swapToken);
    }

    /**
    * @dev Returns price estimator address
    */
    function getPriceEstimator()
    external
    view
    returns(address)
    {
        return address(_priceEstimator);
    }

    /**
    * @dev Returns information about payment details
    * @param id Payment id
    */
    function getPaymentDetails(uint256 id) external view returns(
        address token,
        uint256 amount,
        uint256 releaseTime,
        address sender,
        address beneficiary,
        uint256 createdAt,
        Status status
    )
    {
        require(_idVsPayment[id].amount != 0, "[Validation] Payment details not found");

        Payment memory payment = _idVsPayment[id];
        token = payment.token;
        amount = payment.amount;
        releaseTime = payment.releaseTime;
        sender = payment.sender;
        beneficiary = payment.beneficiary;
        createdAt = payment.createdAt;
        status = payment.status;

        return(
            token,
            amount,
            releaseTime,
            sender,
            beneficiary,
            createdAt,
            status
        );
    }

    /**
    * @dev Returns all payment ids for beneficiary
    * @param user Address of the user
    */
    function getBeneficiaryPaymentIds(address user)
    external 
    view 
    returns (uint256[] memory ids)
    {
        return _beneficiaryVsPaymentIds[user];
    }

    /**
    * @dev Returns all payment ids for sender
    * @param user Address of the user
    */
    function getSenderPaymentIds(address user)
    external
    view
    returns (uint256[] memory ids)
    {
        return _senderVsPaymentIds[user];
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

    /**
    * @dev Sets maximum fee in ETH
    * @param ethAmountInWei Maximum fee amount in wei
    */
    function setMaxFeeInEth(uint256 ethAmountInWei)
    external
    onlyOwner
    {
        _maxFeeInEth = ethAmountInWei;
    }

    function getFeeInEthForEth(uint256 amount)
    public
    view
    returns (uint256) 
    {
        return Math.min(amount.mul(_ethFeePercentage).div(100), _maxFeeInEth); //1% of ETH amount
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
            return Math.min(percentage.mul(ethFeeInWei).div(tokenTotalSupply), _maxFeeInEth);
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
        uint256 feesInEth = calcFeeUsingTotalSupply ? getFeeInEthForERC20UsingTotalSupply(amount, token) : getFeeInEthForERC20(amount, token);
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

    /**
    * @dev Allows user to schedule payment. In case of ERC-20 token the user will
    * first have to approve the contract to spend on his/her behalf
    * @param tokenAddress Address of the token to be paid
    * @param amount Amount of tokens to pay
    * @param releaseTime release time after which tokens to be released. In seconds
    * @param beneficiary Address of the beneficiary
    * @param isFeeInSwap Bool to check if fee to be paid in swap token or not
    */
    function schedulePayment(
        address tokenAddress,
        uint256 amount,
        uint256 releaseTime,
        address payable beneficiary,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    external
    payable
    whenNotPaused
    {
        _schedulePayment(
            tokenAddress,
            amount,
            releaseTime,
            beneficiary,
            msg.value,
            fee,
            isFeeInSwap,
            calcFeeUsingTotalSupply
        );
    }

    /**
    * @dev Helper method to schedule payment
    */
    function _schedulePayment(
        address tokenAddress,
        uint256 amount,
        uint256 releaseTime,
        address payable beneficiary,
        uint256 value,
        uint256 fee,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    returns(uint256)
    {
        require(amount > 0, "[Validation] The amount has to be larger than 0");
        if(!isFreeToken(tokenAddress)) {
            require(fee > 0, "[Validation] The fee has to be larger than 0");
        }
        require(beneficiary != address(0), "[Validation] Invalid beneficiary address");

        uint256 remValue = value;

        if(ETH_ADDRESS == tokenAddress) {
            _scheduleETH(
                amount,
                fee,
                releaseTime,
                beneficiary,
                value,
                isFeeInSwap
            );

            if(isFeeInSwap) {
                remValue = remValue.sub(amount);
            } else {
                remValue = remValue.sub(amount).sub(fee);
            }
        }
        else {
            _scheduleERC20(
                tokenAddress,
                amount,
                fee,
                releaseTime,
                beneficiary,
                value,
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );

            if(!isFeeInSwap) {
                remValue = remValue.sub(fee);
            }
        }

        emit PaymentScheduled(
            tokenAddress,
            msg.sender,
            beneficiary,
            _paymentId,
            amount,
            releaseTime,
            fee,
            isFeeInSwap,
            calcFeeUsingTotalSupply
        );

        return remValue;
    }

    /**
    * @dev Helper method to schedule payment in ETH
    */
    function _scheduleETH(
        uint256 amount,
        uint256 fee,
        uint256 releaseTime,
        address payable beneficiary,
        uint256 value,
        bool isFeeInSwap
    )
    private
    {
        //Transferring fee to the wallet
        if(isFeeInSwap){
            require(value >= amount, "[Validation] Enough ETH not sent");
            uint256 minRequiredFeeInSwap = getFeeInSwapForETH(amount);
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
            uint256 minRequiredFeeInEth = getFeeInEthForEth(amount);
            require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
            require(value >= amount.add(minRequiredFeeInEth), "[Validation] Enough ETH not sent");
            (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
            require(success, "[Validation] Transfer of fee failed");
        }

        _paymentId = _paymentId.add(1);

        _idVsPayment[_paymentId] = Payment({
            token: ETH_ADDRESS,
            amount: amount,
            releaseTime: releaseTime,
            sender: msg.sender,
            beneficiary: beneficiary,
            createdAt: block.timestamp,
            status: Status.OPEN
        });
        _beneficiaryVsPaymentIds[beneficiary].push(_paymentId);
        _senderVsPaymentIds[msg.sender].push(_paymentId);
    }

    /**
    * @dev Helper method to schedule payment in ERC-20 tokens
    */
    function _scheduleERC20(
        address token,
        uint256 amount,
        uint256 fee,
        uint256 releaseTime,
        address payable beneficiary,
        uint256 value,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    private
    onlyContract(token)
    {
        if(!isFreeToken(token)) {
            //Transfer fee to the wallet
            if(isFeeInSwap){
                uint256 minRequiredFeeInSwap = getFeeInSwapForERC20(amount, token, calcFeeUsingTotalSupply);
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
                uint256 minRequiredFeeInEth = calcFeeUsingTotalSupply ? getFeeInEthForERC20UsingTotalSupply(amount, token) : getFeeInEthForERC20(amount, token);
                require(fee >= minRequiredFeeInEth, "[Validation] Fee (ETH) is below minimum required fee");
                require(value >= minRequiredFeeInEth, "[Validation] msg.value doesn't contain enough ETH for fee");
                (bool success,) = _feesWallet.call.value(minRequiredFeeInEth)("");
                require(success, "[Validation] Transfer of fee failed");
            }
        }

        //Transfer required amount of tokens to the contract from user balance
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _paymentId = _paymentId.add(1);

        _idVsPayment[_paymentId] = Payment({
            token: token,
            amount: amount,
            releaseTime: releaseTime,
            sender: msg.sender,
            beneficiary: beneficiary,
            createdAt: block.timestamp,
            status: Status.OPEN
        });
        _beneficiaryVsPaymentIds[beneficiary].push(_paymentId);
        _senderVsPaymentIds[msg.sender].push(_paymentId);
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

    /**
    * @dev Allows user to schedule payment. In case of ERC-20 token the user will
    * first have to approve the contract to spend on his/her behalf
    * @param tokenAddress Address of the token to be paid
    * @param amounts List of amount of tokens to pay
    * @param releaseTimes List of release times after which tokens to be released. In seconds
    * @param beneficiaries List of addresses of the beneficiaries
    * @param isFeeInSwap Bool to check if fee to be paid in swap token or not
    */
    function scheduleBulkPayment(
        address tokenAddress,
        uint256[] calldata amounts,
        uint256[] calldata releaseTimes,
        address payable[] calldata beneficiaries,
        uint256[] calldata fees,
        bool isFeeInSwap,
        bool calcFeeUsingTotalSupply
    )
    external
    payable
    whenNotPaused
    {
        uint256 remValue = msg.value;
        require(amounts.length == releaseTimes.length, "SwapSmartLock: Invalid input");
        require(amounts.length == beneficiaries.length, "SwapSmartLock: Invalid input");
        require(amounts.length == fees.length, "SwapSmartLock: Invalid input");

        for(uint256 i = 0; i < amounts.length; i++) {
            remValue = _schedulePayment(
                tokenAddress,
                amounts[i],
                releaseTimes[i],
                beneficiaries[i],
                remValue,
                fees[i],
                isFeeInSwap,
                calcFeeUsingTotalSupply
            );
        }
    }

    /**
    * @dev Allows beneficiary of payment to release payment after release time
    * @param id Id of the scheduled payment
    */
    function release(uint256 id)
    external
    canRelease(id)
    {
        Payment memory payment = _idVsPayment[id];
        if(ETH_ADDRESS == payment.token) {
            _releaseETH(id);
        }
        else {
            _releaseERC20(id);
        }

        emit PaymentReleased(
            id,
            payment.beneficiary,
            payment.token
        );
    }

    /**
    * @dev Returns whether given payment can be released or not
    * @param id id of a payment
    */
    function releasable(uint256 id)
    public
    view
    returns(bool)
    {
        Payment memory payment = _idVsPayment[id];
        if( (payment.status == Status.OPEN) && (payment.releaseTime <= block.timestamp) )
        {
            return true;
        }
        return false;
    }

    /**
    * @dev Helper method to release ETH
    */
    function _releaseETH(uint256 id)
    private
    {
        Payment storage payment = _idVsPayment[id];
        payment.status = Status.CLOSED;
        (bool success,) = payment.beneficiary.call.value(payment.amount)("");
        require(success, "[Release] Failed to transfer ETH");
    }

    /**
    * @dev Helper method to release ERC-20
    */
    function _releaseERC20(uint256 id)
    private
    {
        Payment storage payment = _idVsPayment[id];
        payment.status = Status.CLOSED;
        IERC20(payment.token).safeTransfer(payment.beneficiary, payment.amount);
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