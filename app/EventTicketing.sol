// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventTicketing {
    address public organizer;
    uint256 public ticketPrice;
    mapping(uint256 => Ticket) private tickets;
    uint256 private ticketCount;

    event TicketIssued(uint256 ticketId);
    event TicketPurchased(uint256 ticketId, address indexed buyer);
    event TicketValidated(uint256 ticketId);

    struct Ticket {
        bool purchased;
        bool isUsed;
        string qrCode;
    }

    constructor(uint256 _ticketPrice) {
        organizer = msg.sender;
        ticketPrice = _ticketPrice;
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the organizer can perform this action");
        _;
    }

    modifier ticketExists(uint256 ticketId) {
        require(ticketId > 0 && ticketId <= ticketCount, "Invalid ticket ID");
        _;
    }

    function createTicket(string memory _qrCode) public onlyOrganizer returns (uint256) {
        ticketCount++;
        tickets[ticketCount] = Ticket({
            purchased: false,
            isUsed: false,
            qrCode: _qrCode
        });
        emit TicketIssued(ticketCount);
        return ticketCount;
    }

    function buyTicket(uint256 ticketId) public payable ticketExists(ticketId) {
        require(msg.value == ticketPrice, "Wrong ticket price,");
        require(tickets[ticketId].purchased == false, "Already purchased");

        tickets[ticketId].purchased = true;

        emit TicketPurchased(ticketId, msg.sender);
    }

    // getQRCode, get underlying ticketId value, verifyTicket
    function verifyTicket(uint256 ticketId) public onlyOrganizer ticketExists(ticketId) {
        require(!tickets[ticketId].isUsed, "Ticket has already been used");

        tickets[ticketId].isUsed = true;
        emit TicketValidated(ticketId);
    }

    function isPurchased(uint256 ticketId) public view ticketExists(ticketId) returns (bool) {
        return tickets[ticketId].purchased;
    }

    function isUsed(uint256 ticketId) public view ticketExists(ticketId) returns (bool) {
        return tickets[ticketId].isUsed;
    }

    function getQRCode(uint256 ticketId) public view ticketExists(ticketId) returns (string memory) {
        return tickets[ticketId].qrCode;
    }
}
