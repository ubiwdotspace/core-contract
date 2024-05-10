// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IVotingManager {
    function getVoteResults(string calldata _roomId) external view returns (uint256[5] memory);
    function getAverageStarRating(address spaceOwner, string calldata roomId) external view returns (uint8);
}

contract SpaceRoomManager is Ownable {
    IVotingManager public votingManager;
    IERC721 public nftContract;

    // Subscription duration in seconds, initially set to 30 days
    uint256 public defaultSubscriptionDuration = 2592000;

    // Percentage of subscription fees that will be allocated to claimable fees (80%)
    uint256 public claimablePercentage = 80;

    uint256 private flatformFee = 0;

    constructor(address initialOwner) Ownable(initialOwner) {}

    struct Room {
        string roomId;  // Room ID as a string
        uint256 subscriptionFee;  // Subscription fee for the room
        uint256 claimableFees;  // Fees that the room creator can currently claim
        mapping(address => uint256) subscribers; // Maps subscriber address to their subscription expiry timestamp
    }

    struct Space {
        address spaceOwner;
        string[] roomIds; // List of all room IDs (as strings) in this space
        mapping(string => Room) rooms; // Mapping of room ID to Room struct
    }

    mapping(address => Space) public spaces; // Mapping from address to Space struct

    event SpaceCreated(address spaceOwner);
    event RoomCreated(address spaceOwner, string roomId, uint256 subscriptionFee);
    event FeesClaimed(address indexed spaceOwner, uint256 totalAmount);
    event SubscriberAddedOrExtended(address indexed spaceOwner, string roomId, address subscriber, uint256 newExpiry);
    event DefaultSubscriptionDurationChanged(uint256 newDuration);
    event ClaimablePercentageChanged(uint256 newPercentage);

    // Modifier to ensure only the voting manager can call certain functions
    modifier onlyVotingManager() {
        require(msg.sender == address(votingManager), "Caller is not the voting manager");
        _;
    }

    // Function to set the addresses of the voting manager and NFT contract
    function setExternalContracts(address _votingManager, address _nftContract) external onlyOwner {
        require(_votingManager != address(0), "Invalid voting manager address");
        require(_nftContract != address(0), "Invalid NFT contract address");
        votingManager = IVotingManager(_votingManager);
        nftContract = IERC721(_nftContract);
    }

    // Function to create a space for the caller, only if the caller owns an NFT
    function createSpace() public {
        // Ensure msg.sender owns at least one of the required NFTs
        require(nftContract.balanceOf(msg.sender) > 0, "Caller does not own the required NFT");

        Space storage newSpace = spaces[msg.sender];
        require(newSpace.spaceOwner == address(0), "Space already exists for this address");

        newSpace.spaceOwner = msg.sender;

        emit SpaceCreated(msg.sender);
    }

    // Function to add a room to the space associated with the caller
    function addRoomToSpace(string memory _roomId, uint256 _subscriptionFee) public {
        require(bytes(_roomId).length > 0, "Room ID cannot be empty");

        Space storage space = spaces[msg.sender];
        require(space.spaceOwner == msg.sender, "Caller is not the space owner");
        require(bytes(space.rooms[_roomId].roomId).length == 0, "Room ID already exists");

        Room storage newRoom = space.rooms[_roomId];
        newRoom.roomId = _roomId;
        newRoom.subscriptionFee = _subscriptionFee;
        newRoom.claimableFees = 0;

        space.roomIds.push(_roomId);

        emit RoomCreated(msg.sender, _roomId, _subscriptionFee);
    }

    // Function for subscribers to join or extend a subscription by sending their fees to the contract
    function addOrExtendSubscription(address spaceOwner, string memory _roomId) public payable {
        Space storage space = spaces[spaceOwner];
        require(space.spaceOwner == spaceOwner, "Space not found for this address");

        Room storage room = space.rooms[_roomId];
        require(bytes(room.roomId).length != 0, "Room not found");
        require(msg.value == room.subscriptionFee, "Incorrect subscription fee");

        // Calculate the amount that will be allocated to claimable fees
        uint256 claimableAmount = (msg.value * claimablePercentage) / 100;

        // Determine if the user already has an active subscription
        uint256 currentExpiry = room.subscribers[msg.sender];
        uint256 newExpiry;

        if (currentExpiry == 0 || currentExpiry < block.timestamp) {
            // New subscription or expired subscription
            newExpiry = block.timestamp + defaultSubscriptionDuration;
        } else {
            // Extend the existing subscription
            newExpiry = currentExpiry + defaultSubscriptionDuration;
        }

        // Update the subscriber's expiry timestamp
        room.subscribers[msg.sender] = newExpiry;
        // Increase the room's claimable fees within the contract
        room.claimableFees += claimableAmount;
        flatformFee += msg.value - claimableAmount;

        emit SubscriberAddedOrExtended(spaceOwner, _roomId, msg.sender, newExpiry);
    }

    // Function to claim all fees from all rooms in a space owned by the caller
    function claimFeeFromSpace() public {
        Space storage space = spaces[msg.sender];
        require(space.spaceOwner == msg.sender, "Caller is not the space owner");

        uint256 totalFees = 0;

        for (uint256 i = 0; i < space.roomIds.length; i++) {
            string memory roomId = space.roomIds[i];
            Room storage room = space.rooms[roomId];

            // Fetch the average star rating (e.g., 42 means 4.2 stars)
            uint8 averageStarRating = votingManager.getAverageStarRating(msg.sender, roomId);
            // console.log(averageStarRating);
            // Calculate fee increase based on stars and claimablePercentage
            uint256 feeIncrease = room.claimableFees * (100 - claimablePercentage) / 100 * averageStarRating / 50;
            // console.log(feeIncrease);

            // Increase the claimable fees
            room.claimableFees += feeIncrease;
            flatformFee -=feeIncrease;
            // Add the entire amount to the total fees to be claimed
            totalFees += room.claimableFees;
            // console.log(totalFees);

            // Reset the claimable fees for this room to zero
            room.claimableFees = 0;
        }

        require(totalFees > 0, "No fees to claim");

        // Transfer the accumulated fees to the space owner
        payable(msg.sender).transfer(totalFees);

        emit FeesClaimed(msg.sender, totalFees);
    }


    function setDefaultSubscriptionDuration(uint256 newDuration) external onlyOwner {
        require(newDuration > 0, "Subscription duration must be greater than zero");
        defaultSubscriptionDuration = newDuration;
        emit DefaultSubscriptionDurationChanged(newDuration);
    }

    function setClaimablePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage >= 50 && newPercentage <= 100, "Claimable percentage must be between 50 and 100");
        claimablePercentage = newPercentage;
        emit ClaimablePercentageChanged(newPercentage);
    }

    // Function to check if a subscriber has an active subscription to a room
    function isSubscriptionActive(address spaceOwner, string calldata roomId, address subscriber) external view returns (bool) {
        Space storage space = spaces[spaceOwner];
        require(space.spaceOwner == spaceOwner, "Space not found for this address");

        Room storage room = space.rooms[roomId];
        require(bytes(room.roomId).length != 0, "Room not found");

        // Check if the subscription is still active by comparing the expiry timestamp to the current time
        return room.subscribers[subscriber] > block.timestamp;
    }
    // Function to withdraw any ETH in the contract
    function withdraw() external onlyOwner {
        payable(owner()).transfer(flatformFee);
    }
}
