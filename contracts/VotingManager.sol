// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISpaceRoomManager {
    function isSubscriptionActive(address spaceOwner, string calldata roomId, address subscriber) external view returns (bool);
}

contract VotingManager {
    ISpaceRoomManager public spaceRoomManager;

    struct Vote {
        bool hasVoted;
        uint8 stars; // Rating from 1 to 5
    }

    struct RoomVotes {
        mapping(address => Vote) votes;
        uint256[5] results; // Array to store votes for each star rating (index 0 -> 1 star, index 1 -> 2 stars, etc.)
    }

    mapping(address => mapping(string => RoomVotes)) private votingRecords;

    event Voted(address indexed spaceOwner, string roomId, address subscriber, uint8 stars);

    // Constructor to set the address of the SpaceRoomManager contract
    constructor(address _spaceRoomManagerAddress) {
        require(_spaceRoomManagerAddress != address(0), "Invalid SpaceRoomManager address");
        spaceRoomManager = ISpaceRoomManager(_spaceRoomManagerAddress);
    }
    
    modifier onlySpaceRoomManager(){
        require(msg.sender == address(spaceRoomManager), "Caller is not the SpaceRoomManager");
        _;
    }

    // Function to cast or change a vote for a room
    function voteForRoom(address spaceOwner, string calldata roomId, uint8 stars) external {
        // Ensure the subscriber has an active subscription to this room
        require(spaceRoomManager.isSubscriptionActive(spaceOwner, roomId, msg.sender), "Not eligible to vote");

        // Ensure the star rating is between 1 and 5
        require(stars >= 1 && stars <= 5, "Invalid star rating");

        // Get the voting data for the room
        RoomVotes storage roomVotes = votingRecords[spaceOwner][roomId];

        // Check if the subscriber has already voted
        Vote storage existingVote = roomVotes.votes[msg.sender];

        if (existingVote.hasVoted) {
            // Decrement the count for the previous vote's star rating
            roomVotes.results[existingVote.stars - 1]--;
        }

        // Update to the new vote and increment the count for the new star rating
        existingVote.hasVoted = true;
        existingVote.stars = stars;
        roomVotes.results[stars - 1]++;

        emit Voted(spaceOwner, roomId, msg.sender, stars);
    }

    // Function to view the voting results for a room
        // Function to calculate the average star rating for a room
    function getAverageStarRating(address spaceOwner, string calldata roomId) public view returns (uint256) {
        RoomVotes storage roomVotes = votingRecords[spaceOwner][roomId];

        uint256 totalVotes = 0;
        uint256 sumOfStars = 0;

        // Calculate the sum of star ratings and the total number of votes
        for (uint8 i = 0; i < 5; i++) {
            uint256 starCount = roomVotes.results[i];
            totalVotes += starCount;
            sumOfStars += starCount * (i + 1);
        }

        // If there are no votes, return zero
        if (totalVotes == 0) {
            return 0;
        }

        // Calculate the average star rating scaled to one decimal place
        uint256 average = (sumOfStars * 10) / totalVotes;

        return average;
    }

    // Function to check if a subscriber has voted for a room
    function hasVoted(address spaceOwner, string calldata roomId, address subscriber) external view returns (bool) {
        return votingRecords[spaceOwner][roomId].votes[subscriber].hasVoted;
    }
}
