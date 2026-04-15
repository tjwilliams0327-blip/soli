// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title BayHouseRental
 * @notice Book the Bay House, pay by the day, and don't forget to leave.
 */
contract BayHouseRental {

    // State Variables

    address payable public owner;   // landlord
    uint public ratePerDay;         // cost per day in wei
    uint public availableFrom;      // unix timestamp: when the house is free again
    uint public totalEarned;        // lifetime earnings tracker
    string public houseLocation;    // e.g. "123 Bay Dr, Gulf Shores, AL"

    // Events

    event Booked(address indexed guest, uint numDays, uint totalPaid, uint availableFrom);
    event RateUpdated(uint oldRate, uint newRate);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Log(address indexed sender, string message);

    // Constructor

    constructor(string memory _houseLocation) {
        owner         = payable(msg.sender);
        ratePerDay    = 2 ether;
        availableFrom = block.timestamp;   // available right now
        totalEarned   = 0;
        houseLocation = _houseLocation;
    }

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function.");
        _;
    }

    modifier houseIsAvailable() {
        require(block.timestamp >= availableFrom, "Bay House is not available yet.");
        _;
    }

    // Public Functions

    /**
     * @notice Check whether the Bay House is currently available.
     */
    function isAvailable() public view returns (bool) {
        return block.timestamp >= availableFrom;
    }

    /**
     * @notice Returns the unix timestamp when the house becomes free.
     *         Returns 0 if it is already available.
     */
    function getAvailableFrom() public view returns (uint) {
        if (isAvailable()) {
            return 0;
        }
        return availableFrom;
    }

    /**
     * @notice Book the Bay House for a given number of days.
     *         Must send at least ratePerDay * numDays in ether.
     * @param numDays Number of days to book
     */
    function bookBayHouse(uint numDays) public payable houseIsAvailable {
        require(numDays > 0, "Must book at least one day.");

        uint minOffer = ratePerDay * numDays;
        require(msg.value >= minOffer, "Take your broke arse home.");

        // Forward payment to owner
        (bool sent, ) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether.");

        // Mark house as unavailable for numDays
        availableFrom = block.timestamp + (numDays * 1 days);
        totalEarned  += msg.value;

        emit Booked(msg.sender, numDays, msg.value, availableFrom);
        emit Log(msg.sender, "I got the Bay House, loser!");
        emit Log(owner, "Bay House has been booked.");
    }

    /**
     * @notice Owner can make the house available immediately (early checkout).
     */
    function makeBayHouseAvailable() public onlyOwner {
        availableFrom = block.timestamp;
        emit Log(msg.sender, "Bay House is now available.");
    }

    /**
     * @notice Owner can update the nightly rate.
     * @param newRate New rate in wei
     */
    function updateRate(uint newRate) public onlyOwner {
        require(newRate > 0, "Rate must be greater than zero.");
        uint oldRate = ratePerDay;
        ratePerDay   = newRate;
        emit RateUpdated(oldRate, newRate);
        emit Log(msg.sender, "Bay House rate has been updated.");
    }

    /**
     * @notice Transfer ownership of the contract to a new address.
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address.");
        require(newOwner != owner,      "Already the owner.");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        emit Log(msg.sender, "Ownership has been transferred.");
    }
}
