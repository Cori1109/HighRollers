// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HighRoller is ERC721Enumerable, Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // constants
    uint256 constant MAX_ELEMENTS = 7777;
    uint256 constant PURCHASE_LIMIT1 = 20;
    uint256 constant PURCHASE_LIMIT2 = 3;
    uint256 constant STAGE1_PRICE = 0.0777 ether;
    uint256 constant STAGE2_PRICE = 0.08547 ether;
    uint256 constant STAGE3_PRICE = 0.09829 ether;
    uint256 constant BOUNTY_AMOUNT = 0.25974 ether;
    uint256 constant NUM_OF_BOUNTY = 77;
    enum STAGE { FAMILY_SALE, PRE_SALE, PUBLIC_SALE }

    // state variable
    STAGE public CURRENT_STAGE = STAGE.FAMILY_SALE;
    bool public MINTING_PAUSED = true;
    string public baseTokenURI;
    string public _contractURI = "";
    uint256 randNonce = 0;

    Counters.Counter private _tokenIdTracker;

    // whitelist variable
    mapping(address => bool) private friendWhiteList;        // for private sale of friends and family
    mapping(address => bool) private discordWhiteList;  // for discord presale
    
    mapping(uint256 => address) private claimedList;
    mapping(address => uint256) private _allowListClaimed;

    // bounty whitelist
    mapping(address => bool) bountyList;

    constructor() ERC721("HighRoller", "HighRoller"){
    }

    function setPauseMinting(bool _pause) public onlyOwner{
        MINTING_PAUSED = _pause;
    }

    function privateSale(uint256 numberOfTokens) external payable {
        require(!MINTING_PAUSED, "Minting is not active");
        require(friendWhiteList[msg.sender], "You are not on the friend white list");
        require(CURRENT_STAGE == STAGE.FAMILY_SALE, "Current stage should be FAMILY_SALE");
        require(totalSupply() < MAX_ELEMENTS, 'All tokens have been minted');
        require(totalSupply() + numberOfTokens < MAX_ELEMENTS, 'Purchase would exceed max supply');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= PURCHASE_LIMIT1, 'Purchase exceeds max allowed');
        require(STAGE1_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdTracker.increment();

            claimedList[_tokenIdTracker.current()] = msg.sender; // should be checked
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdTracker.current());
        }
    }

    function preSale(uint256 numberOfTokens) external payable {
        require(!MINTING_PAUSED, "Minting is not active");
        require(discordWhiteList[msg.sender], "You are not on the discord white list");
        require(CURRENT_STAGE == STAGE.PRE_SALE, "Current stage should be PRE_SALE");
        require(totalSupply() < MAX_ELEMENTS, 'All tokens have been minted');
        require(totalSupply() + numberOfTokens < MAX_ELEMENTS, 'Purchase would exceed max supply');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= PURCHASE_LIMIT2, 'Purchase exceeds max allowed');
        require(STAGE2_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdTracker.increment();

            claimedList[_tokenIdTracker.current()] = msg.sender; // should be checked
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdTracker.current());
        }
    }

    function publicMint(uint256 numberOfTokens) external payable {
        require(!MINTING_PAUSED, "Minting is not active");
        require(CURRENT_STAGE == STAGE.PUBLIC_SALE, "Current stage should be PUBLIC_SALE");
        require(totalSupply() < MAX_ELEMENTS, 'All tokens have been minted');
        require(totalSupply() + numberOfTokens < MAX_ELEMENTS, 'Purchase would exceed max supply');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= PURCHASE_LIMIT2, 'Purchase exceeds max allowed');
        require(STAGE3_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdTracker.increment();

            claimedList[_tokenIdTracker.current()] = msg.sender; // should be checked
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdTracker.current());
        }
    }

    function openBounty() external onlyOwner {
        uint256 index = 0;
        uint256 totalSupply = totalSupply();

        while(true) {
            uint256 selectedIdx = randMod(totalSupply);
            address selectedClaimer = claimedList[selectedIdx + 1];
            if (!bountyList[selectedClaimer]) {
                bountyList[selectedClaimer] = true;
                payable(selectedClaimer).transfer(BOUNTY_AMOUNT);
                index ++;
                if (index >= NUM_OF_BOUNTY)
                    break;
            }
        }
    }

    // returns random number between 0 to _modulus
    function randMod(uint256 _modulus) internal returns(uint256)
    {
        // increase nonce
        randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp,
                                                msg.sender,
                                                randNonce))) %
                                                _modulus;
    }

    function setFriendWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            friendWhiteList[addresses[i]] = true;
        }
    }

    function setDiscordWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            discordWhiteList[addresses[i]] = true;
        }
    }

    function setStage(uint256 _stage) external onlyOwner {
        CURRENT_STAGE = STAGE(_stage);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}