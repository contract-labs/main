pragma solidity ^0.8.17;

import "https://github.com/sueun-dev/ERC721A_GOMZ/blob/main/contracts/ERC721A.sol";
import "https://github.com/sueun-dev/ERC721_GOMZ/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol";

contract CLERC721A is ERC721A, Ownable{

    uint256 public OG_MAX_SUPPLY = 100;
    uint256 public WL1_MAX_SUPPLY = 200;
    uint256 public WL2_MAX_SUPPLY = 1000;
    uint256 public MAX_SUPPLY = 1000;
    //example price
    uint256 public OGRoll = 1 ether;
    uint256 public WL1Roll = 2 ether;
    uint256 public WL2Roll = 3 ether;
    uint256 public publicRoll = 4 ether;

    mapping(address => bool) public OGListed;
    uint256 public numOGlisted;

    mapping(address => bool) public WL1Listed;
    uint256 public numWLListed1;

    mapping(address => bool) public WL2Listed;
    uint256 public numWLListed2;

    string private _baseTokenURI;
    string public notRevealedUri;

    bool public revealed = false;

    //sale start false or true
    bool public OGIsSale = false;
    bool public WL1IsSale = false;
    bool public WL2IsSale = false;
    bool public PublicIsSale = false;

    address private constant payoutAddress1 =
        //(Add your owner address);

    constructor(string memory baseTokenURI, string memory _initNotRevealedUri) ERC721A("contract-labs", "cl_NFT") {
        //baseTokenURI = before reveal
        //setNotRevealedURI = after reveal
        _baseTokenURI = baseTokenURI;
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
    }

    function OGmintByETH(uint256 quantity) external payable callerIsUser{
        require(OGIsSale, "Sale has not started");
        require(OGListed[msg.sender] == true, "You are not OG list");
        require(quantity + _numberMinted(msg.sender) <= 2, "Exceeded the limit per wallet");
        require(totalSupply() + quantity <= OG_MAX_SUPPLY, "Not enough tokens(NFT) left");
        require(quantity <= 2, "you can get 2 NFTs per transact");
        require(msg.value == (OGRoll * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function WL1mintByETH(uint256 quantity) external payable callerIsUser{
        require(WL1IsSale, "Sale has not started");
        require(WL1Listed[msg.sender] == true, "You are not white list");

        if(OGListed[msg.sender] == true) {
            require(quantity + _numberMinted(msg.sender) <= 3, "Exceeded the limit per wallet");
        }

        else {
            require(quantity + _numberMinted(msg.sender) <= 1, "Exceeded the limit per wallet");
        }

        require(totalSupply() + quantity <= WL1_MAX_SUPPLY, "Not enough tokens(NFT) left");
        require(quantity <= 1, "you can get 1 NFTs per transact");
        require(msg.value == (WL1Roll * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function WL2mintByETH(uint256 quantity) external payable callerIsUser{
        require(WL2IsSale, "Sale has not started");
        require(WL2Listed[msg.sender] == true, "You are not white list");
        require(totalSupply() + quantity <= WL2_MAX_SUPPLY, "Not enough tokens(NFT) left");
        require(quantity <= 10, "you can get 10 NFTs per transact");
        require(msg.value == (WL2Roll * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function PublicmintByETH(uint256 quantity) external payable callerIsUser{
        require(PublicIsSale, "Sale has not started");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens(NFT) left");
        require(quantity <= 10, "you can get 10 NFTs per transact");
        require(msg.value == (publicRoll * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens(NFT) left");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(payoutAddress1).transfer(address(this).balance);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {

        if(revealed) {
            return notRevealedUri; 
        }
        return _baseTokenURI;
    }

    function OGsetSale() public onlyOwner {
        OGIsSale = !OGIsSale;
    }

    function WL1setSale() public onlyOwner {
        WL1IsSale = !WL1IsSale;
    }

    function WL2setSale() public onlyOwner {
        WL2IsSale = !WL2IsSale;
    }

    function PublicsetSale() public onlyOwner {
        PublicIsSale = !PublicIsSale;
    }

    function addOG(address[] memory _users) public onlyOwner {
        uint256 size = _users.length;
       
        for (uint256 i=0; i< size; i++){
            address user = _users[i];
            OGListed[user] = true;
        }
        numOGlisted += _users.length;
    }

    function add1Whitelist(address[] memory _users) public onlyOwner {
        uint256 size = _users.length;
       
        for (uint256 i=0; i< size; i++){
            address user = _users[i];
            WL1Listed[user] = true;
        }
        numWLListed1 += _users.length;
    }

    function add2Whitelist(address[] memory _users) public onlyOwner {
        uint256 size = _users.length;

        for (uint256 i=0; i< size; i++){
            address user = _users[i];
            WL2Listed[user] = true;
        }
        numWLListed2 += _users.length;
    }
}
