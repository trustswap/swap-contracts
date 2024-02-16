pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

contract SwapStakingContract is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, PausableUpgradeSafe, ReentrancyGuardUpgradeSafe {

    using SafeMath for uint256;
    using Math for uint256;
    using Address for address;
    using Arrays for uint256[];

    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");

    // EVENTS
    event StakeDeposited(address indexed account, uint256 amount);
    event WithdrawInitiated(address indexed account, uint256 amount, uint256 initiateDate);
    event WithdrawExecuted(address indexed account, uint256 amount, uint256 reward);
    event RewardsWithdrawn(address indexed account, uint256 reward);
    event RewardsDistributed(uint256 amount);

    // STRUCT DECLARATIONS
    struct StakeDeposit {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 entryRewardPoints;
        uint256 exitRewardPoints;
        bool exists;
    }

    // STRUCT WITHDRAWAL
    struct WithdrawalState {
        uint256 initiateDate;
        uint256 amount;
    }

    // CONTRACT STATE VARIABLES
    IERC20 public token;
    address public rewardsAddress;
    uint256 public maxStakingAmount;
    uint256 public currentTotalStake;
    uint256 public unstakingPeriod;

    //reward calculations
    uint256 private totalRewardPoints;
    uint256 public rewardsDistributed;
    uint256 public rewardsWithdrawn;
    uint256 public totalRewardsDistributed;

    mapping(address => StakeDeposit) private _stakeDeposits;
    mapping(address => WithdrawalState) private _withdrawStates;

    // MODIFIERS
    modifier guardMaxStakingLimit(uint256 amount)
    {
        uint256 resultedStakedAmount = currentTotalStake.add(amount);
        require(resultedStakedAmount <= maxStakingAmount, "[Deposit] Your deposit would exceed the current staking limit");
        _;
    }

    modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    // PUBLIC FUNCTIONS
    function initialize(address _token, address _rewardsAddress, uint256 _maxStakingAmount, uint256 _unstakingPeriod)
    public
    onlyContract(_token)
    {
        __SwapStakingContract_init(_token, _rewardsAddress, _maxStakingAmount, _unstakingPeriod);
    }

    function __SwapStakingContract_init(address _token, address _rewardsAddress, uint256 _maxStakingAmount, uint256 _unstakingPeriod)
    internal
    initializer
    {
        require(
            _token != address(0),
            "[Validation] Invalid swap token address"
        );
        require(_maxStakingAmount > 0, "[Validation] _maxStakingAmount has to be larger than 0");
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapStakingContract_init_unchained();

        pause();
        setRewardAddress(_rewardsAddress);
        unpause();

        token = IERC20(_token);
        maxStakingAmount = _maxStakingAmount;
        unstakingPeriod = _unstakingPeriod;
    }

    function __SwapStakingContract_init_unchained()
    internal
    initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(REWARDS_DISTRIBUTOR_ROLE, _msgSender());
    }

    function pause()
    public
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SwapStakingContract: must have pauser role to pause");
        _pause();
    }

    function unpause()
    public
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SwapStakingContract: must have pauser role to unpause");
        _unpause();
    }

    function setRewardAddress(address _rewardsAddress)
    public
    whenPaused
    {
        require(hasRole(OWNER_ROLE, _msgSender()), "[Validation] The caller must have owner role to set rewards address");
        require(_rewardsAddress != address(0), "[Validation] _rewardsAddress is the zero address");
        require(_rewardsAddress != rewardsAddress, "[Validation] _rewardsAddress is already set to given address");
        rewardsAddress = _rewardsAddress;
    }

    function setTokenAddress(address _token)
    external
    onlyContract(_token)
    whenPaused
    {
        require(hasRole(OWNER_ROLE, _msgSender()), "[Validation] The caller must have owner role to set token address");
        require(
            _token != address(0),
            "[Validation] Invalid swap token address"
        );
        token = IERC20(_token);
    }

    function deposit(uint256 amount)
    external
    nonReentrant
    whenNotPaused
    {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(stakeDeposit.endDate == 0, "[Deposit] You have already initiated the withdrawal");

        uint256 oldPrincipal = stakeDeposit.amount;
        uint256 reward = _computeReward(stakeDeposit);
        uint256 newPrincipal = oldPrincipal.add(amount).add(reward);
        require(newPrincipal > oldPrincipal, "[Validation] The stake deposit has to be larger than 0");

        uint256 resultedStakedAmount = currentTotalStake.add(newPrincipal.sub(oldPrincipal));
        require(resultedStakedAmount <= maxStakingAmount, "[Deposit] Your deposit would exceed the current staking limit");

        stakeDeposit.amount = newPrincipal;
        stakeDeposit.startDate = block.timestamp;
        stakeDeposit.exists = true;
        stakeDeposit.entryRewardPoints = totalRewardPoints;

        currentTotalStake = resultedStakedAmount;

        // Transfer the Tokens to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "[Deposit] Something went wrong during the token transfer");
        
        if( reward > 0 ) {
            //calculate withdrawed rewards in single distribution cycle
            rewardsWithdrawn = rewardsWithdrawn.add(reward);
            require(token.transferFrom(rewardsAddress, address(this), reward), "[Deposit] Something went wrong while transferring reward");
        }
        
        emit StakeDeposited(msg.sender, amount.add(reward));
    }

    function initiateWithdrawal(uint256 withdrawAmount)
    external
    nonReentrant
    whenNotPaused
    {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        WithdrawalState storage withdrawState = _withdrawStates[msg.sender];
        require(withdrawAmount > 0, "[Initiate Withdrawal] Invalid withdrawal amount");
        require(withdrawAmount <= stakeDeposit.amount, "[Initiate Withdrawal] Withdraw amount exceed the stake amount");
        require(stakeDeposit.exists && stakeDeposit.amount != 0, "[Initiate Withdrawal] There is no stake deposit for this account");
        require(stakeDeposit.endDate == 0, "[Initiate Withdrawal] You have already initiated the withdrawal");
        require(withdrawState.amount == 0, "[Initiate Withdrawal] You have already initiated the withdrawal");

        stakeDeposit.endDate = block.timestamp;
        stakeDeposit.exitRewardPoints = totalRewardPoints;
        withdrawState.amount = withdrawAmount;
        withdrawState.initiateDate = block.timestamp;

        currentTotalStake = currentTotalStake.sub(withdrawAmount);

        emit WithdrawInitiated(msg.sender, withdrawAmount, block.timestamp);
    }

    function executeWithdrawal()
    external
    nonReentrant
    whenNotPaused
    {
        StakeDeposit memory stakeDeposit = _stakeDeposits[msg.sender];
        WithdrawalState memory withdrawState = _withdrawStates[msg.sender];

        require(stakeDeposit.endDate != 0 || withdrawState.amount != 0, "[Withdraw] Withdraw amount is not initialized");
        require(stakeDeposit.exists && stakeDeposit.amount != 0, "[Withdraw] There is no stake deposit for this account");

        // validate enough days have passed from initiating the withdrawal
        uint256 daysPassed = (block.timestamp - stakeDeposit.endDate) / 1 days;
        require(unstakingPeriod <= daysPassed, "[Withdraw] The unstaking period did not pass");

        uint256 amount = withdrawState.amount != 0 ? withdrawState.amount : stakeDeposit.amount;
        uint256 reward = _computeReward(stakeDeposit);

        require(stakeDeposit.amount >= amount, "[withdraw] Remaining stakedeposit amount must be higher than withdraw amount");
        if (stakeDeposit.amount > amount) {
            _stakeDeposits[msg.sender].amount = _stakeDeposits[msg.sender].amount.sub(amount);
            _stakeDeposits[msg.sender].endDate = 0;
            _stakeDeposits[msg.sender].entryRewardPoints = totalRewardPoints;
        }
        else {
            delete _stakeDeposits[msg.sender];
        }

        require(token.transfer(msg.sender, amount), "[Withdraw] Something went wrong while transferring your initial deposit");
        
        if( reward > 0 ) {
            //calculate withdrawed rewards in single distribution cycle
            rewardsWithdrawn = rewardsWithdrawn.add(reward);
            require(token.transferFrom(rewardsAddress, msg.sender, reward), "[Withdraw] Something went wrong while transferring your reward");
        }

        _withdrawStates[msg.sender].amount = 0;
        _withdrawStates[msg.sender].initiateDate = 0;

        emit WithdrawExecuted(msg.sender, amount, reward);
    }

    function withdrawRewards()
    external
    nonReentrant
    whenNotPaused
    {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(stakeDeposit.exists && stakeDeposit.amount != 0, "[Rewards Withdrawal] There is no stake deposit for this account");
        require(stakeDeposit.endDate == 0, "[Rewards Withdrawal] You already initiated the full withdrawal");

        uint256 reward = _computeReward(stakeDeposit);

        require(reward > 0, "[Rewards Withdrawal] The reward amount has to be larger than 0");
        
        stakeDeposit.entryRewardPoints = totalRewardPoints;

        //calculate withdrawed rewards in single distribution cycle
        rewardsWithdrawn = rewardsWithdrawn.add(reward);

        require(token.transferFrom(rewardsAddress, msg.sender, reward), "[Rewards Withdrawal] Something went wrong while transferring your reward");

        emit RewardsWithdrawn(msg.sender, reward);
    }

    // VIEW FUNCTIONS FOR HELPING THE USER AND CLIENT INTERFACE
    function getStakeDetails(address account)
    external
    view
    returns (uint256 initialDeposit, uint256 startDate, uint256 endDate, uint256 rewards)
    {
        require(_stakeDeposits[account].exists && _stakeDeposits[account].amount != 0, "[Validation] This account doesn't have a stake deposit");

        StakeDeposit memory s = _stakeDeposits[account];

        return (s.amount, s.startDate, s.endDate, _computeReward(s));
    }

    function _computeReward(StakeDeposit memory stakeDeposit)
    private
    view
    returns (uint256)
    {
        uint256 rewardsPoints = 0;

        if ( stakeDeposit.endDate == 0 )
        {
            rewardsPoints = totalRewardPoints.sub(stakeDeposit.entryRewardPoints);
        }
        else
        {
            //withdrawal is initiated
            rewardsPoints = stakeDeposit.exitRewardPoints.sub(stakeDeposit.entryRewardPoints);
        }
        return stakeDeposit.amount.mul(rewardsPoints).div(10 ** 18);
    }

    function distributeRewards()
    external
    nonReentrant
    whenNotPaused
    {
        require(hasRole(REWARDS_DISTRIBUTOR_ROLE, _msgSender()),
            "[Validation] The caller must have rewards distributor role");
        _distributeRewards();
    }

    function _distributeRewards()
    private
    whenNotPaused
    {
        require(hasRole(REWARDS_DISTRIBUTOR_ROLE, _msgSender()),
            "[Validation] The caller must have rewards distributor role");
        require(currentTotalStake > 0, "[Validation] not enough total stake accumulated");
        uint256 rewardPoolBalance = token.balanceOf(rewardsAddress);
        require(rewardPoolBalance > 0, "[Validation] not enough rewards accumulated");

        uint256 newlyAdded = rewardPoolBalance.add(rewardsWithdrawn).sub(rewardsDistributed);
        uint256 ratio = newlyAdded.mul(10 ** 18).div(currentTotalStake);
        totalRewardPoints = totalRewardPoints.add(ratio);
        rewardsDistributed = rewardPoolBalance;
        rewardsWithdrawn = 0;
        totalRewardsDistributed = totalRewardsDistributed.add(newlyAdded);
        
        emit RewardsDistributed(newlyAdded);
    }

    function version() public pure returns (string memory) {
        return "v2";
    }
}