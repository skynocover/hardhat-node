// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract SharingMember {
  using SafeMath for uint256;

  // Add the library methods
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  // Declare a set state variable
  EnumerableMap.AddressToUintMap private _sharingMembers;

  function _setSharing(address[] memory addresses, uint8[] memory numSlots) internal {
    for (uint256 i = 0; i < addresses.length; i++) {
      if (numSlots[i] == 0) {
        _sharingMembers.remove(addresses[i]);
      } else {
        _sharingMembers.set(addresses[i], numSlots[i]);
      }
    }

    uint256 total = 0;
    uint256 len = _sharingMembers.length();
    for (uint256 i = 0; i < len; i++) {
      (, uint256 num) = _sharingMembers.at(i);
      total += num;
    }

    require(total == 100, "total must be 100");
  }

  /**
   * @dev Returns the number of accounts that will shared. Can be used
   * together with {getSharingMember} to enumerate all bearers of a sharing.
   */
  function getSharingMemberCount() public view virtual returns (uint256) {
    return _sharingMembers.length();
  }

  /**
   * @dev Returns one of the accounts that will shared. `index` must be a
   * value between 0 and {getSharingMemberCount}, non-inclusive.
   */
  function getSharingMember(uint256 index) public view virtual returns (address, uint256) {
    return _sharingMembers.at(index);
  }

  function isSharingMember(address addr) public view virtual returns (bool) {
    return _sharingMembers.contains(addr);
  }
}
