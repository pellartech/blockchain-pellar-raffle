// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RaffleFinance is VRFConsumerBase, Ownable {
  struct Raffle {
    bool seeded;
    address owner;
    string name;
    uint256 totalWinners;
    uint256 drawnWinnersAt;
    uint256 seedNumber;
    uint256 mark;
    address[] entries;
    address[] winners;
  }

  // constants
  address public constant VRF_COORDINATOR_ADDRESS = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
  address public constant LINK_ADDRESS = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
  bytes32 public constant VRF_KEY_HASH = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
  uint256 public constant VRF_FEE = 0.0001 * (10 ** 18);

  uint256 public constant CREATE_RAFFLE_FEE = 5 * (10 ** 18); // 5 matic

  // variables
  uint256 public registered;
  mapping(bytes32 => uint256) public requests;
  mapping(uint256 => Raffle) public raffles;

  constructor() VRFConsumerBase(VRF_COORDINATOR_ADDRESS, LINK_ADDRESS) {}

  /** Modifier */
  modifier onlyRaffleOwner(uint256 _raffleId) {
    require(msg.sender == raffles[_raffleId].owner, "Caller is not the raffle owner");
    _;
  }

  /* VRF */

  // verified
  function createRandomSeed(uint256 _raffleId) external onlyRaffleOwner(_raffleId) returns (bytes32 _requestId) {
    require(LINK.allowance(msg.sender, address(this)) >= VRF_FEE, "Not enough LINK.");
    LINK.transferFrom(msg.sender, address(this), VRF_FEE);
    _requestId = requestRandomness(VRF_KEY_HASH, VRF_FEE); // get random number after 10 blocks, 0 will be used as base number
    requests[_requestId] = _raffleId;
  }

  // verified
  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    raffles[requests[_requestId]].seeded = true;
    raffles[requests[_requestId]].seedNumber = _randomness; // set random number with request
  }

  /* View functions */

  function getRaffleByOwner(address _owner) public view returns(uint256[] memory) {

  }

  function getRaffleEntriesLength(uint256 _raffleId) public view returns(uint256) {
    return raffles[_raffleId].entries.length;
  }

  function getWinnersLength(uint256 _raffleId) public view returns(uint256) {
    return raffles[_raffleId].winners.length;
  }

  /* Raffle Owner controls */

  function createRaffle(string calldata _name, uint256 _totalWinners) external payable {
    require(msg.value >= CREATE_RAFFLE_FEE, "Matic value incorrect.");

    raffles[registered].owner = msg.sender;
    raffles[registered].name = _name;
    raffles[registered].totalWinners = _totalWinners;
    registered++;
  }

  function addEntries(uint256 _raffleId, address[] calldata _addresses) external onlyRaffleOwner(_raffleId) {
    Raffle storage raffle = raffles[_raffleId];
    require(getWinnersLength(_raffleId) == 0, "Winners drawn");

    for(uint256 i = 0; i < _addresses.length; i++) {
      raffle.entries.push(_addresses[i]);
    }
    raffle.mark = raffle.entries.length;
  }

  function setEntries(uint256 _raffleId, address[] calldata _addresses) external onlyRaffleOwner(_raffleId) {
    Raffle storage raffle = raffles[_raffleId];
    require(getWinnersLength(_raffleId) == 0, "Winners drawn");

    raffle.entries = _addresses;
    raffle.mark = raffle.entries.length;
  }

  function drawWinners(uint256 _raffleId, uint256 _amount) external onlyRaffleOwner(_raffleId) {
    Raffle storage raffle = raffles[_raffleId];

    require(raffle.seeded, "Need VRF seed");
    require(_amount + getWinnersLength(_raffleId) <= getRaffleEntriesLength(_raffleId), "Exceed total entries");
    require(_amount + getWinnersLength(_raffleId) <= raffle.totalWinners, "Exceed total winners");

    uint256 seedNumber = raffle.seedNumber;
    for (uint256 i = 0; i < _amount; i++) {
      uint256 index = uint256(keccak256(abi.encodePacked(seedNumber, block.number, raffle.winners.length, block.timestamp, i, address(this)))) % raffle.mark;

      address winner = raffle.entries[index];
      raffle.winners.push(winner);

      raffle.entries[index] = raffle.entries[raffle.mark - 1];
      raffle.entries[raffle.mark - 1] = winner; // move winner to bound.
      raffle.mark -= 1;
    }

    if (getWinnersLength(_raffleId) == raffle.totalWinners) {
      raffle.drawnWinnersAt = block.timestamp;
    }
  }

  /* Admin controls */
  // verified
  function withdraw() external onlyOwner { // withdraw matic
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
