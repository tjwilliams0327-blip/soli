// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BayHouseRental {

    // state variables
    address payable public owner;
    uint public ratePerDay;
    uint public availableFrom;
    uint public totalEarned;
    string public houseLocation;

    // events
    event Booked(address indexed guest, uint numDays, uint totalPaid, uint availableFrom);
    event RateUpdated(uint oldRate, uint newRate);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Log(address indexed sender, string message);

    constructor(string memory _houseLocation) {
        owner = payable(msg.sender);
        ratePerDay = 2 ether;
        availableFrom = block.timestamp;
        totalEarned = 0;
        houseLocation = _houseLocation;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function.");
        _;
    }

    modifier houseIsAvailable() {
        require(block.timestamp >= availableFrom, "Bay House is not available yet.");
        _;
    }

    // check if the bay house is available
    function isAvailable() public view returns (bool) {
        return block.timestamp >= availableFrom;
    }

    // returns when the house is available, 0 if already available
    function getAvailableFrom() public view returns (uint) {
        if (isAvailable()) {
            return 0;
        }
        return availableFrom;
    }

    // book the bay house for a number of days
    function bookBayHouse(uint numDays) public payable houseIsAvailable {
        require(numDays > 0, "Must book at least one day.");

        // check payment amount
        uint minOffer = ratePerDay * numDays;
        require(msg.value >= minOffer, "Take your broke arse home.");

        // send payment to owner
        (bool sent, ) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether.");

        // set next available date and track earnings
        availableFrom = block.timestamp + (numDays * 1 days);
        totalEarned += msg.value;

        emit Booked(msg.sender, numDays, msg.value, availableFrom);
        emit Log(msg.sender, "I got the Bay House, loser!");
        emit Log(owner, "Bay House has been booked.");
    }

    // owner can make the house available early
    function makeBayHouseAvailable() public onlyOwner {
        availableFrom = block.timestamp;
        emit Log(msg.sender, "Bay House is now available.");
    }

    // owner can update the daily rate
    function updateRate(uint newRate) public onlyOwner {
        require(newRate > 0, "Rate must be greater than zero.");
        uint oldRate = ratePerDay;
        ratePerDay = newRate;
        emit RateUpdated(oldRate, newRate);
        emit Log(msg.sender, "Bay House rate has been updated.");
    }

    // transfer ownership to a new owner
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address.");
        require(newOwner != owner, "Already the owner.");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        emit Log(msg.sender, "Ownership has been transferred.");
    }
}
