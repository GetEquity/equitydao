
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Math.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(uint256 amount);

    uint256 private _released;
    uint256 private _erc20Released;
    address private immutable _beneficiary;
    uint64 private immutable _start; // start date
    uint64 private immutable _duration; // 4 years
    uint64 private immutable _period; // assume na hour 
    uint64 private _lastRelease;
    address private _erc20Token


    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        address erc20TokenAddress
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 periodSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _erc20Token = erc20TokenAddress
        _start = startTimestamp;
        _duration = durationSeconds;
        _period = periodSeconds;
        _lastRelease = 0;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of erc20 token already released
     */
    function erc20Released() public view virtual returns (uint256) {
        return _erc20Released;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        require(now() >= _lastRelease + _period, "EQUITY DAO: Next vesting period not reached");
        uint256 releasable = vestedAmount(_erc20Token, uint64(block.timestamp)) - erc20Released();
        require(releasable > 0, "EQUITY DAO: No vested token available");
        _erc20Released += releasable;
        _lastRelease = now();
        emit ERC20Released(releasable);
        SafeERC20.safeTransfer(IERC20(_erc20Token), beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + erc20Released(), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amout vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > (start() + duration())) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
