pragma solidity 0.6.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {

    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {

        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {

        _paused = false;

    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {

        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IERC20Extended {
    function decimals() external view returns (uint8);
    function burnFrom(address account, uint256 amount) external;
}

interface IPriceEstimator {
    function getEstimatedETHforERC20(
        uint256 erc20Amount,
        address token
    ) external view returns (uint256[] memory);

    function getEstimatedERC20forETH(
        uint256 etherAmountInWei,
        address tokenAddress
    ) external view returns (uint256[] memory);
}

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
