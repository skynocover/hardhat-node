// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./AllowlistPausable.sol";
import "./SharingMember.sol";

contract ERC721ACombination is
  ERC721A,
  Ownable,
  Pausable,
  AllowlistPausable,
  AccessControlEnumerable,
  SharingMember
{
  using SafeMath for uint256;
  using Strings for uint256;

  string public baseURI = "";
  uint256 public nftPrice = 0; // 0.025 ETH
  uint256 public maxSupply = 0;
  uint256 public maxPerAddressMint = 0;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    string memory _baseURI,
    uint256 _nftPrice,
    string memory _blindTokenURI,
    uint256 _maxPerAddressMint,
    uint256 _teamMint
  ) ERC721A(_name, _symbol) {
    maxSupply = _maxSupply;
    baseURI = _baseURI;
    blindTokenURI = _blindTokenURI;
    maxPerAddressMint = _maxPerAddressMint;
    if (_teamMint > 0) {
      _safeMint(msg.sender, _teamMint);
    }
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _pause();
    setNftPrice(_nftPrice);
    address[] memory t = new address[](1);
    t[0] = msg.sender;
    uint8[] memory n = new uint8[](1);
    n[0] = 100;
    _setSharing(t, n);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setBaseURI(string calldata _baseURI) external onlyMember {
    baseURI = _baseURI;
  }

  function setNftPrice(uint256 _nftPrice) public onlyMember {
    nftPrice = _nftPrice;
  }

  function setMaxPerAddressMint(uint256 _maxPerAddressMint) public onlyMember {
    maxPerAddressMint = _maxPerAddressMint;
  }

  ///////////  start of mint  ///////////

  function mint(uint256 quantity) external payable callerIsUser whenNotPaused {
    require(totalSupply() + quantity <= maxSupply, "Purchase would exceed max supply");
    require(balanceOf(msg.sender) + quantity <= maxPerAddressMint, "can not mint this many");

    _safeMint(msg.sender, quantity);
    refundIfOver(nftPrice * quantity);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");

    if (blindBoxOpened) {
      return
        bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } else {
      return blindTokenURI;
    }
  }

  ///////////  end of mint  ///////////

  ///////////  start of pause  ///////////
  function pause() public onlyMember {
    _pause();
  }

  function unpause() public onlyMember {
    _unpause();
  }

  ///////////  end of pause  ///////////

  ///////////  start of blind box  ///////////
  bool public blindBoxOpened = false;
  string public blindTokenURI = "";

  function setBlindTokenURI(string memory _blindTokenURI) public onlyMember {
    blindTokenURI = _blindTokenURI;
  }

  function setBlindBoxOpened(bool _status) external onlyMember {
    blindBoxOpened = _status;
  }

  ///////////  blind box end  ///////////

  /////////// start of allow list  ///////////

  mapping(address => uint256) public allowlist;
  uint256 public allowlistNftPrice = 0;

  function allowlistPause() public onlyMember {
    _allowlistPause();
  }

  function allowlistUnpause() public onlyMember {
    _allowlistUnpause();
  }

  function setAllowlistNftPrice(uint256 _allowlistNftPrice) public onlyMember {
    allowlistNftPrice = _allowlistNftPrice;
  }

  function allowlistMint(uint256 quantity) external payable whenAllowlistNotPaused callerIsUser {
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(totalSupply() + quantity <= maxSupply, "reached max supply");
    require(balanceOf(msg.sender) + quantity <= maxPerAddressMint, "can not mint this many");
    require(quantity <= allowlist[msg.sender], "can not allowlist mint this many");
    allowlist[msg.sender] = allowlist[msg.sender] - quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(allowlistNftPrice * quantity);
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyMember
  {
    require(addresses.length == numSlots.length, "addresses not match numSlots len");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  /////////// end of allow list  ///////////

  ///////////  member  ///////////

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, AccessControlEnumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @dev Restricted to members of the community.
  modifier onlyMember() {
    require(isMember(msg.sender), "Restricted to members.");
    _;
  }

  /// @dev Return `true` if the `account` belongs to the community.
  function isMember(address account) public view virtual returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// @dev Add a member of the community.
  function addMember(address account) public virtual onlyOwner {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// @dev Remove member of the community.
  function removeMember(address account) public virtual onlyOwner {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

  ///////////  end of member ///////////

  //////////  Sharing ///////////

  function updateSharing(address[] memory addresses, uint8[] memory numSlots) public onlyOwner {
    require(totalSupply() < maxSupply, "Sharing cannot be set after sale has ended");
    require(addresses.length == numSlots.length, "addresses not match numSlots len");

    _setSharing(addresses, numSlots);
  }

  //////////  end of Sharing ///////////

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdraw() public onlyMember {
    uint256 balance = address(this).balance;
    uint256 remain = balance;
    uint256 len = getSharingMemberCount();
    for (uint256 i = 0; i < len - 1; i++) {
      (address addr, uint256 sharing) = getSharingMember(i);
      (bool checkMul, uint256 m) = balance.tryMul(sharing);
      require(checkMul, "mul fail, check saringRate");
      (bool checkDiv, uint256 b) = m.tryDiv(100);
      require(checkDiv, "mul fail, check saringRate");
      payable(addr).transfer(b);
      remain -= b;
    }
    (address lastAddr, ) = getSharingMember(len - 1);
    payable(lastAddr).transfer(remain);
  }
}
