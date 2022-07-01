//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Offer {
    uint256 _offerPrice;
    uint256 _offerEndDuration;
    address offerer;
}

struct AllowedToken {
    address erc20Token;
    bool isAllowed;
}

contract NFTAuction is Ownable {
    mapping(address => mapping(uint256 => mapping(address => Offer[])))
        private offers;

    address payable public royaltyWallet;
    mapping(uint256 => AllowedToken) public allowedTokens;

    function addToken(address erc20Token, uint256 index) external onlyOwner {
        allowedTokens[index] = AllowedToken(erc20Token, true);
    }

    function offerNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenIndex,
        uint256 _offerPrice,
        uint256 _offerDuration
    ) external {
        _createNewNFTOffer(
            _nftContractAddress,
            _tokenId,
            allowedTokens[_tokenIndex].erc20Token,
            _offerPrice,
            block.timestamp + _offerDuration
        );
    }

    function _createNewNFTOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress,
        uint256 _offerPrice,
        uint256 _offerEndDuration
    ) internal {
        offers[_nftContractAddress][_tokenId][_erc20TokenAddress].push(
            Offer(_offerPrice, _offerEndDuration, msg.sender)
        );
    }

    function acceptOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress,
        uint256 offerIndex
    ) external {
        Offer memory offer = offers[_nftContractAddress][_tokenId][
            _erc20TokenAddress
        ][offerIndex];
        _transferNftAndPaySeller(
            _nftContractAddress,
            _tokenId,
            _erc20TokenAddress,
            offer
        );
    }

    function _payFeesAndSeller(
        address _offerer,
        address _erc20TokenAddress,
        uint256 _amount
    ) internal {
        uint256 royaltyAmount = (_amount * 25) / 1000;
        IERC20(_erc20TokenAddress).transferFrom(
            _offerer,
            msg.sender,
            _amount - royaltyAmount
        );
        // IERC20(_erc20TokenAddress).transferFrom(
        //     _offerer,
        //     royaltyWallet,
        //     royaltyAmount
        // );
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress,
        Offer memory offer
    ) internal {
        _payFeesAndSeller(offer.offerer, _erc20TokenAddress, offer._offerPrice);
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            offer.offerer,
            _tokenId
        );
        _resetAuction(_nftContractAddress, _tokenId, _erc20TokenAddress);
    }

    function getOffers(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress
    ) external view returns (Offer[] memory) {
        uint256 length = getOfferLength(
            _nftContractAddress,
            _tokenId,
            _erc20TokenAddress
        );
        Offer[] memory offered = new Offer[](length);
        for (uint256 index = 0; index < length; index++) {
            offered[index] = offers[_nftContractAddress][_tokenId][
                _erc20TokenAddress
            ][index];
        }
        return offered;
    }

    function getOfferLength(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress
    ) internal view returns (uint256) {
        return offers[_nftContractAddress][_tokenId][_erc20TokenAddress].length;
    }

    function _resetAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress
    ) internal {
        delete offers[_nftContractAddress][_tokenId][_erc20TokenAddress];
    }
}
