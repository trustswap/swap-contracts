pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract SwapToken is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, ERC20BurnableUpgradeSafe, ERC20PausableUpgradeSafe {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) public {
        __SwapToken_init(name, symbol, decimals, totalSupply);
    }

    function __SwapToken_init(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __SwapToken_init_unchained();
        _mint(_msgSender(), totalSupply * (10 ** uint256(decimals)));
    }

    function __SwapToken_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SwapToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SwapToken: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal 
    override(ERC20UpgradeSafe, ERC20PausableUpgradeSafe)
    {
        require(to != address(this), "SwapToken: can't transfer to contract address itself");
        if( to != _devWallet ) {
            require(blacklisted[from] == false);
            require(blacklisted[to] == false);
        }
        
        super._beforeTokenTransfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount)
    internal 
    override(ERC20UpgradeSafe)
    notBlacklisted(owner)
    notBlacklisted(spender)
    {
        super._approve(owner, spender, amount);
    }

    /**
     * @dev withdraw tokens using a de-facto a low-level safeTransfer without any extra imports [requires the target to be a contract]
     * 
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * 
     * @param tokenContract The address of the token contract to withdraw
     */
    function withdrawTokens(address tokenContract) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "SwapToken [withdrawTokens]: must have admin role to withdraw"
        );

        // address.code is not available in Solidity 0.6.2, so we need to use assembly to check if the target is a contract
        bytes32 codehash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(tokenContract) }
        require(
            codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 && codehash != 0x0,
            "SwapToken [withdrawTokens]: transfer failed - wrong input"
        );
        
        IERC20 tc = IERC20(tokenContract);
        require(
            tc.transfer(
                _msgSender(), 
                tc.balanceOf(address(this))
            ),
            "SwapToken [withdrawTokens] Something went wrong while transferring"
        );
    }

    function version() public pure returns (string memory) {
        return "v4";
    }

    uint256[50] private __gap;

    //BlackListing
    mapping(address => bool) internal blacklisted;
    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check    
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SwapToken [blacklist]: must have admin role to blacklist");
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SwapToken [unBlacklist]: must have admin role to unBlacklist");
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    //Wallet where fees will go
    address private _devWallet;

    function setDevWallet(address wallet) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SwapToken [setDevWallet]: must have admin role to set dev wallet");
        require(
            wallet != address(0),
            "[Validation] wallet is the zero address"
        );
        _devWallet = wallet;
    }

    /**
    * @dev returns the dev wallet address
    */
    function getDevWallet() external view returns(address) {
        return _devWallet;
    }

    function mint(address wallet, uint256 amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SwapToken [mint]: must have admin role to mint");
        require(
            wallet != address(0),
            "[Validation] wallet is the zero address"
        );
        _mint(wallet, amount);
    }
}