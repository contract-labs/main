// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Change ERC721A.sol address.
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CLERC721Aburn is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 8525;
    // on remix, you have to change "VALUE"
    uint256 public PRICE_PER_ETH = 1 ether;
    // Maximum purchase per one transaction
    uint256 public constant maxPurchase = 5;

    string private _baseTokenURI;
    string public notRevealedUri;

    bool public isSale = false;
    bool public revealed = false;

    mapping(address => mapping(address => bool)) public tokenApprovals;

    function approve(address _to, uint256 _tokenId) override  public {
        require(_to != address(0));
        require(ownerOf(_tokenId) == msg.sender);
        tokenApprovals[msg.sender][_to] = true;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override  public {
        require(_to != address(0));
        require(tokenApprovals[_from][msg.sender]);
        tokenApprovals[_from][msg.sender] = false;
        transferFrom(_from, _to, _tokenId);
    }

    constructor(string memory baseTokenURI, string memory _initNotRevealedUri) ERC721A("CL_NFT", "CLN") {
        _baseTokenURI = baseTokenURI;
        setNotRevealedURI(_initNotRevealedUri);
    }

    function mintByETH(uint256 quantity) external payable {
        require(isSale, "Public sale is NOT start");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(quantity <= maxPurchase, "Can only mint 5 NFT at a time");
        require(msg.value >= (PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function burn(address _from, uint256 _tokenId) public {
        require(msg.sender == address(this));
        burn(_from, _tokenId);
    }

    function developerPreMint(uint256 quantity) public onlyOwner {
        require(!isSale, "Not Start");
        require(quantity + _numberMinted(msg.sender) <= 500, "Exceeded the limit");
        require(totalSupply() + quantity <= 500, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {

        if(revealed) { 
        return notRevealedUri; }

        return _baseTokenURI;
    }

    function setSale() public onlyOwner {
        isSale = !isSale;
    }

}
