// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract AllowlistPausable is Context {
  event AllowlistPaused(address account);
  event AllowlistUnpaused(address account);

  bool public allowlistPaused;

  constructor() {
    allowlistPaused = true;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenAllowlistNotPaused() {
    _requireAllowlistNotPaused();
    _;
  }

  modifier whenAllowlistPaused() {
    _requireAllowlistPaused();
    _;
  }

  /**
   * @dev Throws if the contract is paused / unpaused.
   */
  function _requireAllowlistNotPaused() internal view virtual {
    require(!allowlistPaused, "Pausable: paused");
  }

  function _requireAllowlistPaused() internal view virtual {
    require(allowlistPaused, "Pausable: not paused");
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _allowlistPause() internal virtual whenAllowlistNotPaused {
    allowlistPaused = true;
    emit AllowlistPaused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _allowlistUnpause() internal virtual whenAllowlistPaused {
    allowlistPaused = false;
    emit AllowlistUnpaused(_msgSender());
  }
}
