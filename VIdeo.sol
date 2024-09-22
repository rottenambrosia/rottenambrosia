// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Owner.sol";

contract StreamingService is Ownable {

    struct Video {
        uint256 id;
        string title;
        string url;
    }

    uint256 public constant COST = 0.001 ether;
    uint256 public constant REWARD = 1000;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public UploadByOwner;

    struct LockUnlock {
        address owner;  // The original uploader/owner of the video
        address[] accessList;  // Array to store all addresses that have access
        mapping(address => bool) hasAccess;  // A mapping to track access without duplicates
    }

    uint multiply;
    address payable public recipient;

    constructor(address payable _recipient) {
        recipient = _recipient;
    }

    mapping(uint256 => Video) public videos;
    mapping(uint256 => LockUnlock) public LockUnlockVideos;
    mapping(address => uint256[]) public videosByAddress;  // New mapping for address to video numbers
    uint256 public videoCount;

    event VideoUploaded(uint256 id, string title, string _description);
    event VideoPurchased(uint256 videoId, address buyer, string message);

    function buyBalance() public payable {
        multiply = msg.value / COST;
        require(msg.value >= COST, "Minimum need to send 0.001 Test Ether");

        // Transfer the received Ether to the recipient
        recipient.transfer(msg.value);

        // Add the reward balance to the sender's account
        balances[msg.sender] += (REWARD * multiply);
    }

    function uploadVideo(string memory _title, string memory _description) public {
        videoCount++;
        videos[videoCount] = Video(videoCount, _title, _description);
        LockUnlockVideos[videoCount].owner = msg.sender;  // Set the uploader as the owner of the video
        LockUnlockVideos[videoCount].hasAccess[msg.sender] = true;  // Give the uploader access to the video
        LockUnlockVideos[videoCount].accessList.push(msg.sender);  // Add the uploader to the access list

        // Add the video to the list of videos associated with the uploader's address
        videosByAddress[msg.sender].push(videoCount);

        emit VideoUploaded(videoCount, _title, _description);
    }

    function buyVideo(uint256 videoNumber) public {
        require(videoNumber > 0 && videoNumber <= videoCount, "Video does not exist");

        // Ensure that the buyer is not the owner or someone who already has access
        require(!LockUnlockVideos[videoNumber].hasAccess[msg.sender], "You already have access to this video or are the owner");

        require(balances[msg.sender] >= 100, "Insufficient balance");

        // Deduct balance from the buyer
        balances[msg.sender] -= 100;

        // Give the buyer access to the video
        LockUnlockVideos[videoNumber].hasAccess[msg.sender] = true;
        LockUnlockVideos[videoNumber].accessList.push(msg.sender);  // Add the buyer to the access list

        // Add the video to the list of videos associated with the buyer's address
        videosByAddress[msg.sender].push(videoNumber);

        emit VideoPurchased(videoNumber, msg.sender, "Purchased Successfully");
    }

    function getVideo(uint256 _id) public view returns (Video memory) {
        require(_id > 0 && _id <= videoCount, "Video does not exist");

        // Ensure the caller has access to the video (either the owner or someone who bought access)
        require(LockUnlockVideos[_id].hasAccess[msg.sender], "You do not have access to this video");

        return videos[_id];
    }

    // New function to retrieve the list of addresses that have access to a video
    function getAccessList(uint256 videoNumber) public view returns (address[] memory) {
        require(videoNumber > 0 && videoNumber <= videoCount, "Video does not exist");
        return LockUnlockVideos[videoNumber].accessList;
    }

    // New function to retrieve the list of video numbers an address has access to or owns
    function getVideosByAddress(address _addr) public view returns (uint256[] memory) {
        return videosByAddress[_addr];
    }
}
