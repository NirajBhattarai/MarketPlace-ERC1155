//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct List {
    uint256 sellPrice;
    address owner;
    uint256 duration;
}

struct Offer {
    uint256 _offerPrice;
    uint256 _offerEndDuration;
    address offerer;
}

struct AllowedToken {
    address erc20Token;
    bool isAllowed;
}

contract Marketplace is Ownable {
    mapping(address => mapping(uint256 => List)) public lists;
    mapping(address => mapping(uint256 => mapping(address => Offer[])))
        private offers;
    mapping(uint256 => AllowedToken) public allowedTokens;

    address payable public royaltyWallet;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event TokenListed(
        address nftAddress,
        address seller,
        uint256 tokenid,
        uint256 tokenPrice,
        uint256 duration
    );

    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/

    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Sender doesn't own NFT"
        );
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender != IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Owner cannot buy on own NFT"
        );
        _;
    }

    modifier isSaleOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(_saleOngoing(_nftContractAddress, _tokenId), "Sale is Over");
        _;
    }

    modifier _isOfferAvailable(Offer memory offer) {
        require(_offerAvailable(offer), "Sale is Over");
        _;
    }

    modifier isSaleDurationOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_saleOngoing(_nftContractAddress, _tokenId),
            "Sale is not yet over"
        );
        _;
    }

    modifier isSellerOwner(
        address _nftContractAddress,
        address _lister,
        uint256 _tokenId
    ) {
        require(
            _lister == IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Sender doesn't own NFT"
        );
        _;
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/

    function changeRoyaltyWallet(address payable _newRoyaltyAddress) public {
        royaltyWallet = _newRoyaltyAddress;
    }

    function addToken(address erc20Token, uint256 index) external onlyOwner {
        require(allowedTokens[index].erc20Token==address(0),"Token Already Assigned");
        allowedTokens[index] = AllowedToken(erc20Token, true);
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║        ETH DIRECT SALE      ║
      ║                             ║
      ╚═════════════════════════════╝*/
    /**********************************/

    function listToken(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) external onlyNftSeller(_nftContractAddress, _tokenId) {
        lists[_nftContractAddress][_tokenId] = List(
            _price,
            msg.sender,
            block.timestamp + _duration
        );
        emit TokenListed(
            _nftContractAddress,
            msg.sender,
            _tokenId,
            _price,
            block.timestamp + _duration
        );
    }

    function createSale(address _nftContractAddress, uint256 _tokenId)
        public
        payable
        notNftSeller(_nftContractAddress, _tokenId)
        isSaleOngoing(_nftContractAddress, _tokenId)
    {
        List memory list = lists[_nftContractAddress][_tokenId];
        require(list.sellPrice <= msg.value, "InSufficient Balance Send");
        _transferNftAndPaySeller(
            _nftContractAddress,
            list.sellPrice,
            list.owner,
            msg.sender,
            _tokenId
        );
    }

    function updateBuyPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newBuyPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        isSaleOngoing(_nftContractAddress, _tokenId)
    {
        lists[_nftContractAddress][_tokenId].sellPrice = _newBuyPrice;
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 amount,
        address _nftSeller,
        address _nftRecipient,
        uint256 _tokenId
    ) internal isSellerOwner(_nftContractAddress, _nftSeller, _tokenId) {
        _payFeesAndSeller(amount, _nftSeller);
        IERC721(_nftContractAddress).transferFrom(
            _nftSeller,
            _nftRecipient,
            _tokenId
        );
        _resetListing(_nftContractAddress, _tokenId);
    }

    function _payFeesAndSeller(uint256 _amount, address _nftSeller) internal {
        uint256 royaltyAmount = (_amount * 25) / 1000;
        payable(_nftSeller).transfer(_amount - royaltyAmount);
        royaltyWallet.transfer(royaltyAmount);
    }

    function _resetListing(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        lists[_nftContractAddress][_tokenId].sellPrice = 0;
        lists[_nftContractAddress][_tokenId].owner = address(0);
        lists[_nftContractAddress][_tokenId].duration = 0;
    }

    function _saleOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 lastSaleTime = lists[_nftContractAddress][_tokenId].duration;
        return (block.timestamp < lastSaleTime);
    }

    function cancelListing(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        _resetListing(_nftContractAddress, _tokenId);
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║    END ETH DIRECT SALE      ║
      ║                             ║
      ╚═════════════════════════════╝*/
    /**********************************/

    /*╔═════════════════════════════╗
      ║    Auctioning               ║
      ║                             ║
      ╚═════════════════════════════╝*/
    /**********************************/

    function offerNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenIndex,
        uint256 _offerPrice,
        uint256 _offerDuration
    ) external {
        require(allowedTokens[_tokenIndex].isAllowed,"Not Allowed To Trade With This Token");
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
        IERC20(_erc20TokenAddress).transferFrom(
            _offerer,
            royaltyWallet,
            royaltyAmount
        );
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20TokenAddress,
        Offer memory offer
    ) internal _isOfferAvailable(offer) {
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

    function _offerAvailable(Offer memory offer) internal view returns (bool) {
        uint256 lastSaleTime = offer._offerEndDuration;
        return (block.timestamp < lastSaleTime);
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
