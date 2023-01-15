// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    /**
      * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
      * token will be the concatenation of the `baseURI` and the `tokenId`.
      */
    string _baseTokenURI;
    // set to https://nft-collection-sneh1999.vercel.app/api/ at deployment 
    // with Sneh's vercel-served app

   //  _price is the price of one Crypto Dev NFT
   //   internally, figures get converted into wei, hence uint256 for too big a number
   // keywords, ether, wei, finney, etc.
    uint256 public _price = 0.01 ether;

    // _paused is used to pause the contract in case of an emergency
    bool public _paused;

    // max number of CryptoDevs
    uint256 public constant MAX_TOKEN_IDS = 20;

    // total number of tokenIds minted
    uint256 public tokenIds;

    // IWhitelist-interface contract instance
    IWhitelist whitelist;

    // boolean to keep track of whether presale started or not
    bool public presaleStarted;

    // timestamp for when presale would end
    // not bool but a timestamp. Big number, hence uint256
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused {
      require(!_paused, "Contract currently paused");
      _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    function startPresale() public onlyOwner {
      presaleStarted = true;
      // Set presaleEnded time as current timestamp + 5 minutes
      // Solidity has cool syntax for timestamps (seconds, minutes, hours, days, years)
      presaleEnded = block.timestamp + 5 minutes;
    }

    function presaleMint() public payable onlyWhenNotPaused {
      // 4 checks:
      // 1. Presale status?
      // 2. Whitelisted address ?
      // 3. maxTokenIds minted ?
      // 4. msg.value sufficient ?
      require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
      // access whitelistedAddresses mapping that returns a bool inside require
      require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
      // even whitelisted address may not be able to mint this NFT if it got late in minting one
      // and limit of 20 got reached already.
      require(tokenIds < MAX_TOKEN_IDS, "Exceeded maximum Crypto Devs supply");
      require(msg.value >= _price, "Ether sent is not correct");
      // after these 4 checks, we'll increment tokenIds by 1
      // same tokenIds variable to keep a track of minted NFTs for both whitelisted and new users
      // possibility, that none of the new user is able to mint any NFT
      tokenIds++;
      // change state var tokenIds before minting (actual action/txn)

      //_safeMint is a safer version of the _mint function as it ensures that
      // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
      // If the address being minted to is not a contract, it works the same way as _mint
      _safeMint(msg.sender, tokenIds);
      // zero-based tokenIds enumerability, that's why tokenIds < maxTokenIds (NOT <=)
    }

    // presaleMint() and regular mint() will run only mutually exclusively
    // onlyWhenNotPaused won't ever work on these at the same time
    function mint() public payable onlyWhenNotPaused { 
      // can give more realistic msg - "Presale not yet started"
      // by changing a variable to true (from false) inside presaleMint()
      // so that a user knowes that he cannot regular mint() when presaleMint() not even started
      require(presaleStarted && block.timestamp >=  presaleEnded, "Presale has not ended yet");
      require(tokenIds < MAX_TOKEN_IDS, "Exceed maximum Crypto Devs supply");
      require(msg.value >= _price, "Ether sent is not correct");
      tokenIds += 1;
      _safeMint(msg.sender, tokenIds);    
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }
    
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() public onlyOwner {
      address _owner = owner();
      uint256 _amount = address(this).balance;
      (bool success, ) = _owner.call{value: _amount}("");
      require(success, "Failed to send ETH");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}