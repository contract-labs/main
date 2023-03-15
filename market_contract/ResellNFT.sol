// SPDX-License-Identifier: MIT LICENSE
// Created By Sueun Cho
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ResellNFT is IERC721Receiver, ReentrancyGuard {

    address payable owner;
    uint256 listingFee = 0.0025 ether;

    ERC721A nft;

    mapping(uint256 => List) public vaultItems;

    struct List {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event NFTListCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

     constructor(ERC721A _nft) {
        owner = payable(msg.sender);
        nft = _nft;
    }

    function listSale(uint256 tokenId, uint256 price) public payable nonReentrant {
        require(nft.ownerOf(tokenId) == msg.sender, "NFT not yours");
        require(vaultItems[tokenId].tokenId == 0, "NFT already listed");
        require(price > 0, "Amount must be higher than 0");
        require(msg.value == listingFee, "Please transfer 0.0025 crypto to pay listing fee");

        vaultItems[tokenId] =  List(tokenId, payable(msg.sender), payable(address(this)), price, false);
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit NFTListCreated(tokenId, msg.sender, address(this), price, false);
    }

    function buyNft(uint256 tokenId) public payable nonReentrant {
        uint256 price = vaultItems[tokenId].price;
        require(msg.value == price, "Transfer Total Amount to complete transaction");
        vaultItems[tokenId].seller.transfer(msg.value);
        payable(0x6d4e23d391761Cfb49C2115F600aBE90e4F45Bfa).transfer(listingFee);
        nft.transferFrom(address(this), msg.sender, tokenId);
        vaultItems[tokenId].sold = true;
        delete vaultItems[tokenId];
    }

    function cancelSale(uint256 tokenId) public nonReentrant {
        require(vaultItems[tokenId].seller == msg.sender, "NFT not yours");
        nft.transferFrom(address(this), msg.sender, tokenId);
        delete vaultItems[tokenId];
    }

    function nftListings() public view returns (List[] memory) {
        uint256 nftCount = nft.totalSupply();
        uint currentIndex = 0;
        List[] memory items = new List[](nftCount);
        for (uint i = 0; i < nftCount; i++) {
          // (vaultItems[i + 1]) 1번부터 먹게되어있어서 tokenid가 0부터 시작하면 vaultItems[i]로 만들어야 함!
            if (vaultItems[i].owner == address(this)) {
            uint currentId = i;
            List storage currentItem = vaultItems[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
            }
        }
        return items;
    }

    ////////// Below code is NFT dutch auction.

    struct DutchAuction {
        uint256 tokenId;
        address payable seller;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
    }

    mapping(uint256 => DutchAuction) public vaultAuctions;

    event DutchAuctionCreated(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 duration
    );

    function addAction(
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) public payable nonReentrant {
        require(nft.ownerOf(tokenId) == msg.sender, "NFT not yours");
        require(vaultItems[tokenId].tokenId == 0, "NFT already listed");
        require(startPrice > endPrice, "Start price must be higher than end price");
        require(duration > 0, "Duration must be greater than 0");
        require(msg.value == listingFee, "Please transfer 0.0025 crypto to pay listing fee");

        DutchAuction memory auction = DutchAuction({
            tokenId: tokenId,
            seller: payable(msg.sender),
            startPrice: startPrice,
            endPrice: endPrice,
            startTime: block.timestamp,
            duration: duration
        });

        vaultAuctions[tokenId] = auction;
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit DutchAuctionCreated(tokenId, msg.sender, startPrice, endPrice, block.timestamp, duration);
    }

    function buyNftAuction(uint256 tokenId) public payable nonReentrant {
    DutchAuction memory auction = vaultAuctions[tokenId];
        require(auction.tokenId != 0, "Auction doesn't exist");

        uint256 timePassed = block.timestamp - auction.startTime;
        require(timePassed <= auction.duration, "Auction has ended");

        uint256 priceDiff = auction.startPrice - auction.endPrice;
        uint256 priceDrop = (priceDiff * timePassed) / auction.duration;
        uint256 currentPrice = auction.startPrice - priceDrop;

        require(msg.value >= currentPrice, "Transfer the current price to complete transaction");

        auction.seller.transfer(currentPrice);
        payable(0x6d4e23d391761Cfb49C2115F600aBE90e4F45Bfa).transfer(listingFee);
        nft.transferFrom(address(this), msg.sender, tokenId);
        delete vaultAuctions[tokenId];
    }

    ////////// Below code is NFT english auction.

    struct EnglishAuction {
        uint256 tokenId;
        address payable seller;
        uint256 minPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 startTime;
        uint256 duration;
        bool finalized;
    }

    mapping(uint256 => EnglishAuction) public vaultEnglishAuctions;

    event EnglishAuctionCreated(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 minPrice,
        uint256 startTime,
        uint256 duration
    );  

    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount
    );  

    event AuctionFinalized(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );

    function addEnglishAuction(
        uint256 tokenId,
        uint256 minPrice,
        uint256 duration
    ) public payable nonReentrant {
        require(nft.ownerOf(tokenId) == msg.sender, "NFT not yours");
        require(vaultItems[tokenId].tokenId == 0, "NFT already listed");
        require(minPrice > 0, "Minimum price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        require(msg.value == listingFee, "Please transfer 0.0025 crypto to pay listing fee");

        EnglishAuction memory auction = EnglishAuction({
            tokenId: tokenId,
            seller: payable(msg.sender),
            minPrice: minPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            duration: duration,
            finalized: false
        });

        vaultEnglishAuctions[tokenId] = auction;
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit EnglishAuctionCreated(tokenId, msg.sender, minPrice, block.timestamp, duration);
    }

    function placeBid(uint256 tokenId) public payable nonReentrant {
        EnglishAuction storage auction = vaultEnglishAuctions[tokenId];
        require(auction.tokenId != 0, "Auction doesn't exist");
        require(block.timestamp <= auction.startTime + auction.duration, "Auction has ended");
        require(msg.value > auction.highestBid && msg.value >= auction.minPrice, "Bid must be higher than the current highest bid and minimum price");

        if (auction.highestBidder != address(0)) {
            auction.highestBidder.transfer(auction.highestBid); // Refund previous highest bidder
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function finalizeAuction(uint256 tokenId) public nonReentrant {
        EnglishAuction storage auction = vaultEnglishAuctions[tokenId];
        require(auction.tokenId != 0, "Auction doesn't exist");
        require(block.timestamp > auction.startTime + auction.duration, "Auction has not ended yet");
        require(!auction.finalized, "Auction has already been finalized");

        if (auction.highestBidder != address(0)) {
            auction.seller.transfer(auction.highestBid);
            nft.transferFrom(address(this), auction.highestBidder, tokenId);
            emit AuctionFinalized(tokenId, auction.highestBidder, auction.highestBid);
        } else {
            nft.transferFrom(address(this), auction.seller, tokenId); // Return NFT to the seller if no bids were placed
        }

        auction.finalized = true;
        delete vaultEnglishAuctions[tokenId];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
        ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

}   
