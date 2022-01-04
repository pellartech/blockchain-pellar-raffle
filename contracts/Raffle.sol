// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RaffleContract is VRFConsumerBase, Ownable {
    struct Raffle {
        bool seeded;
        uint256 seedNumber;
        uint256 mark;
        uint256 totalWinners;
        address[] entries;
        address[] winners;
    }

    // constants
    address public constant VRF_COORDINATOR_ADDRESS = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    address public constant LINK_ADDRESS = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    bytes32 public constant VRF_KEY_HASH = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 public constant VRF_FEE = 0.0001 * (10 ** 18);

    // variables
    mapping(uint256 => Raffle) public raffles;
    mapping(bytes32 => uint256) public requests;

    constructor() VRFConsumerBase(VRF_COORDINATOR_ADDRESS, LINK_ADDRESS) {}

    /**
    * VRF control
     */

    // verified
    function createRandomSeed(uint256 _raffleId) external onlyOwner returns (bytes32 _requestId) {
        require(LINK.balanceOf(address(this)) >= VRF_FEE, "Not enough LINK.");
        _requestId = requestRandomness(VRF_KEY_HASH, VRF_FEE); // get random number after 10 blocks, 0 will be used as base number
        requests[_requestId] = _raffleId;
    }

    // verified
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        raffles[requests[_requestId]].seeded = true;
        raffles[requests[_requestId]].seedNumber = _randomness; // set random number with request
    }

    // verified
    function withdrawLink() external onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        LINK.transfer(msg.sender, balance);
    }

    /**
    * View functions
     */

    function getRaffleEntries(uint256 _raffleId, uint256 _start, uint256 _end) public view returns(address[] memory _entries) {
        Raffle memory raffle = raffles[_raffleId];
        _end = _end > raffle.entries.length ? raffle.entries.length : _end;
        uint256 size = _end - _start;
        _entries = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            _entries[i] = raffle.entries[_start + i];
        }
    }

    function getRaffleWinners(uint256 _raffleId, uint256 _start, uint256 _end) public view returns(address[] memory _winners) {
        Raffle memory raffle = raffles[_raffleId];
        _end = _end > raffle.winners.length ? raffle.winners.length : _end;
        uint256 size = _end - _start;
        _winners = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            _winners[i] = raffle.winners[_start + i];
        }
    }

    function getRaffleEntriesLength(uint256 _raffleId) public view returns(uint256) {
        return raffles[_raffleId].entries.length;
    }
    
    function getWinnersLength(uint256 _raffleId) public view returns(uint256) {
        return raffles[_raffleId].winners.length;
    }

    /**
    * Admin control
     */

    // verified
    function createRaffle(uint256 _raffleId, uint256 _totalWinners) external onlyOwner {
        require(getWinnersLength(_raffleId) == 0, "Winners already drew.");
        raffles[_raffleId].totalWinners = _totalWinners;
    }

    function addEntries(uint256 _raffleId, address[] calldata _addresses) external onlyOwner {
        Raffle storage raffle = raffles[_raffleId];
        require(getWinnersLength(_raffleId) == 0, "Winners already drew.");

        for(uint256 i = 0; i < _addresses.length; i++) {
            raffle.entries.push(_addresses[i]);
        }
        raffle.mark = raffle.entries.length;
    }

    function setEntries(uint256 _raffleId, address[] calldata _addresses) external onlyOwner {
        Raffle storage raffle = raffles[_raffleId];
        require(getWinnersLength(_raffleId) == 0, "Winners already drew.");

        raffle.entries = _addresses;
        raffle.mark = raffle.entries.length;
    }

    function drawWinners(uint256 _raffleId, uint256 _amount) external onlyOwner {
        Raffle storage raffle = raffles[_raffleId];

        require(raffle.seeded, "Not seeded.");
        require(_amount + getWinnersLength(_raffleId) <= getRaffleEntriesLength(_raffleId), "Exceed total entries.");
        require(_amount + getWinnersLength(_raffleId) <= raffle.totalWinners, "Exceed total winners.");

        uint256 seedNumber = raffle.seedNumber;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 index = uint256(keccak256(abi.encodePacked(seedNumber, block.number, raffle.winners.length, block.timestamp, i, address(this)))) % raffle.mark;

            address winner = raffle.entries[index];
            raffle.winners.push(winner);
            
            raffle.entries[index] = raffle.entries[raffle.mark - 1];
            raffle.entries[raffle.mark - 1] = winner; // move winner to bound.
            raffle.mark -= 1;
        }
    }

    function withdraw() external onlyOwner { // withdraw matic
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
