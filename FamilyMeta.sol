// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title FamilyMetaToken
 * @dev Implementation of the FAMATOKEN with upgradeability and pausable functionalities.
 */
contract FamilyMetaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    uint8 private constant _decimals = 18;
    address public multisigWallet;

    // Events declaration
    event Minted(address indexed to, uint256 amount);
    event TokenPaused(address account);
    event TokenUnpaused(address account);
    event Burned(address indexed from, uint256 amount);
    event MultisigWalletChanged(address indexed previousWallet, address indexed newWallet);

    // Modifier to restrict access to the multisig wallet
    modifier onlyMultisig() {
        require(msg.sender == multisigWallet, "Not authorized");
        _;
    }

    /**
     * @dev Initializes the contract with the owner and multisig wallet addresses.
     * @param owner Owner address.
     * @param _multisigWallet Multisig wallet address.
     */
    function initialize(address owner, address _multisigWallet) external initializer {
        require(owner != address(0), "Owner address cannot be zero.");
        require(_multisigWallet != address(0), "Multisig wallet address cannot be zero.");
        __ERC20_init("FamilyMeta", "FAMA");
        __Ownable_init(owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        multisigWallet = _multisigWallet;
        uint256 mintAmount = 50000000000 * (10 ** _decimals); // 50 billion tokens
        _mint(owner, mintAmount);
        emit Minted(owner, mintAmount);
    }

    /**
     * @dev Pauses all token transfers. Callable by multisig wallet.
     */
    function pause() external onlyMultisig nonReentrant {
        _pause();
        emit TokenPaused(msg.sender);
    }

    /**
     * @dev Unpauses all token transfers. Callable by multisig wallet.
     */
    function unpause() external onlyMultisig nonReentrant {
        _unpause();
        emit TokenUnpaused(msg.sender);
    }

    /**
     * @dev Authorizes the contract to upgrade to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal view override onlyMultisig {
        require(newImplementation != address(0), "New implementation cannot be zero address");
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * @return Decimals places.
     */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Changes the ownership to a new address. Callable by multisig wallet.
     * @param newOwner Address of the new owner.
     */
    function changeOwnership(address newOwner) external onlyMultisig nonReentrant {
        require(newOwner != address(0), "New owner cannot be zero address.");
        transferOwnership(newOwner);
    }

    /**
     * @dev Changes the multisig wallet address to a new address. Callable by multisig wallet.
     * @param newMultisig Address of the new multisig wallet.
     */
    function changeMultisigWallet(address newMultisig) external onlyMultisig nonReentrant {
        require(newMultisig != address(0), "New multisig wallet cannot be zero address.");
        emit MultisigWalletChanged(multisigWallet, newMultisig);
        multisigWallet = newMultisig;
    }

    /**
     * @dev Burns tokens from a specified address. Callable by multisig wallet or owner.
     * @param from Address to burn tokens from.
     * @param amount Amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external nonReentrant {
        require(amount > 0, "Burn amount must be greater than zero");
        require(msg.sender == multisigWallet || msg.sender == owner(), "Not authorized to burn");
        _burn(from, amount);
        emit Burned(from, amount);
    }
}
