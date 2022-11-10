// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is Ownable, VRFConsumerBase {
    uint256 public fee;
    bytes32 public keyHash;
    address[] public players;
    uint256 public maxPlayers;
    bool public gameStarted;
    uint256 public entryFee;
    uint256 public gameId;

    event GameStarted(uint256 gameId, uint256 maxPlayers, uint256 entryFee);
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);
    event PlayerJoined(uint256 gameId, address player);

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfFee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
    }

    // starts the game by setting appropriate variables
    function startGame(uint256 _maxPlayers, uint256 _entryFee)
        public
        onlyOwner
    {
        require(!gameStarted, "Game is currently running");

        maxPlayers = _maxPlayers;
        entryFee = _entryFee;
        gameStarted = true;
        gameId += 1;

        emit GameStarted(gameId, maxPlayers, entryFee);
    }

    // join the game by sending the entry fee
    function joinGame() public payable {
        require(gameStarted, "Game has not been started yet");
        require(players.length < maxPlayers, "Game is full");
        require(msg.value >= entryFee, "Value sent is not equal to entryFee");

        players.push(msg.sender);

        emit PlayerJoined(gameId, msg.sender);

        if (players.length == maxPlayers) {
            getRandomWinner();
        }
    }

    // fulfillRandomness is called by Chainlink VRF once the random number is generated
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override
    {
        uint256 winnerIndex = randomness % players.length;
        address winner = players[winnerIndex];

        (bool sent, ) = winner.call{value: address(this).balance}("");

        require(sent, "Failed to send Ether");

        emit GameEnded(gameId, winner, requestId);

        // reset the game
        gameStarted = false;
    }

    // getRandomWinner generates a random number using Chainlink VRF
    function getRandomWinner() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        return requestRandomness(keyHash, fee);
    }

    // receive function is used to receive Ether
    receive() external payable {}

    // fallback function is used to receive Ether
    fallback() external payable {}
}
