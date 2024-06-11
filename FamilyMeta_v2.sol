// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title FamilyMetaToken
 * @dev Implementation of the FAMATOKEN with upgradeability and pausable functionalities.
 */
contract FamilyMetaToken is Initializable, ERC20PausableUpgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {

    // Events declaration
    event Minted(address indexed to, uint256 amount);
    event TokenPaused(address account);
    event TokenUnpaused(address account);
    event Burned(address indexed from, uint256 amount);
    event OwnershipTransferRequested(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

    // Variable to store the new owner address during ownership transfer process
    address private _newOwner;

    /**
     * @dev Initializes the contract with the owner address.
     * @param owner Owner address.
     */
    function initialize(address owner) external initializer {
        require(owner != address(0), "Owner address cannot be zero.");
        __ERC20_init("FamilyMeta", "FAMA");
        __ERC20Pausable_init();
        __Ownable2Step_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _transferOwnership(owner);
        uint256 mintAmount = 50_000_000_000 * (10 ** decimals()); // 50 billion tokens
        _mint(owner, mintAmount);
        emit Minted(owner, mintAmount);
    }

    /**
     * @dev Pauses all token transfers. Callable by owner.
     */
    function pause() external onlyOwner nonReentrant whenNotPaused {
        _pause();
        emit TokenPaused(msg.sender);
    }

    /**
     * @dev Unpauses all token transfers. Callable by owner.
     */
    function unpause() external onlyOwner nonReentrant whenPaused {
        _unpause();
        emit TokenUnpaused(msg.sender);
    }

    /**
     * @dev Authorizes the contract to upgrade to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        require(newImplementation != address(0), "New implementation cannot be zero address");
    }

    /**
     * @dev Requests a change of ownership to a new address. Callable by owner.
     * @param newOwner Address of the new owner.
     */
    function requestOwnershipTransfer(address newOwner) external onlyOwner nonReentrant whenNotPaused {
        require(newOwner != address(0), "New owner cannot be zero address.");
        _newOwner = newOwner;
        emit OwnershipTransferRequested(owner(), newOwner);
    }

    /**
     * @dev Confirms the change of ownership. Callable by the new owner.
     */
    function confirmOwnershipTransfer() external nonReentrant {
        require(msg.sender == _newOwner, "Only the new owner can confirm ownership transfer.");
        address previousOwner = owner();
        _transferOwnership(_newOwner);
        emit OwnershipTransferConfirmed(previousOwner, _newOwner);
        _newOwner = address(0); // Reset _newOwner
    }

    /**
     * @dev Burns tokens from a specified address. Callable by owner.
     * @param from Address to burn tokens from.
     * @param amount Amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Burn amount must be greater than zero");
        require(msg.sender == owner(), "Not authorized to burn");
        _burn(from, amount);
        emit Burned(from, amount);
    }

    /**
     * @dev Override transfer function to include whenNotPaused.
     * @param recipient The address receiving the tokens.
     * @param amount The amount of tokens being transferred.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Override allowance function to include whenNotPaused.
     * @param owner The address of the token owner.
     * @param spender The address authorized to spend the tokens.
     */
    function allowance(address owner, address spender) public view override whenNotPaused returns (uint256) {
        return super.allowance(owner, spender);
    }

    /**
     * @dev Override transferFrom function to include whenNotPaused.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param amount The amount of tokens being transferred.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Override approve function to include whenNotPaused.
     * @param spender The address authorized to spend the tokens.
     * @param amount The amount of tokens being approved.
     */
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    /**
     * @dev Disable the acceptOwnership function.
     */
    function acceptOwnership() public pure override {
        revert("acceptOwnership function is disabled. Use confirmOwnershipTransfer instead.");
    }

    /**
     * @dev Disable the transferOwnership function.
     */
    function transferOwnership(address) public view override onlyOwner {
        revert("transferOwnership function is disabled. Use requestOwnershipTransfer and confirmOwnershipTransfer instead.");
    }
}
