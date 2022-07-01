//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct List {
  uint256 sellPrice;
  address owner;
  uint256 duration;
}

contract Marketplace is Ownable {
  mapping(address => mapping(uint256 => List[])) private lists;

  address payable public royaltyWallet;

  function listERC1155(
    address _erc1155Address,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration
  ) external {
    _createNewERC1155List(_erc1155Address, _tokenId, _price, _duration);
  }

  function createSale(
    address _erc1155Address,
    uint256 _tokenId,
    uint256 listIndex
  ) external {
    List memory list = lists[_erc1155Address][_tokenId][listIndex];
    _transferNftAndPaySeller(_erc1155Address, _tokenId, list);
  }

  function _transferNftAndPaySeller(
    address _erc1155Address,
    uint256 _tokenId,
    List memory list
  ) internal {
    IERC1155(_erc1155Address).safeTransferFrom(
      list.owner,
      msg.sender,
      _tokenId,
      1,
      ""
    );
    _payFeesAndSeller(list.sellPrice, list.owner);
  }

  function _payFeesAndSeller(uint256 _amount, address _erc1155Owner) internal {}

  function getLists(address _erc1155Address, uint256 _tokenId)
    external
    view
    returns (List[] memory)
  {
    uint256 length = getOfferLength(_erc1155Address, _tokenId);
    List[] memory listed = new List[](length);
    for (uint256 index = 0; index < length; index++) {
      listed[index] = lists[_erc1155Address][_tokenId][index];
    }
    return listed;
  }

  function _createNewERC1155List(
    address _erc1155Address,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration
  ) internal {
    lists[_erc1155Address][_tokenId].push(List(_price, msg.sender, _duration));
  }

  function getOfferLength(address _erc1155Address, uint256 _tokenId)
    internal
    view
    returns (uint256)
  {
    return lists[_erc1155Address][_tokenId].length;
  }
}
