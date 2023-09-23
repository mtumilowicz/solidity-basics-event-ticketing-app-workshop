// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol"; // Import Remix testing library
import "../contracts/EventTicketing.sol"; // Import the EventTicketing contract

contract EventTicketingTest {

    EventTicketing eventTicketing;
    uint256 ticketPrice = 1000000000000000;

    function beforeEach() public {
        eventTicketing = new EventTicketing(ticketPrice);
    }

    function checkOrganizer() public {
        Assert.equal(eventTicketing.organizer(), address(this), "Organizer should be this contract");
    }

    function checkTicketPrice() public {
        Assert.equal(eventTicketing.ticketPrice(), ticketPrice, "Ticket price should be 0.001 ETH");
    }

    function createTicket() public {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        string memory qrCode = eventTicketing.getQRCode(ticketId);
        Assert.equal(qrCode, "QR_CODE_DATA", "QR code should match");
    }

    function buyTicket() public payable {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        eventTicketing.buyTicket{value: ticketPrice, gas: 1000000}(ticketId);
        bool purchased = eventTicketing.isPurchased(ticketId);
        Assert.equal(purchased, true, "Ticket should be purchased");
    }

    function verifyTicket() public payable {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        eventTicketing.buyTicket{value: ticketPrice}(ticketId);
        eventTicketing.verifyTicket(ticketId);
        bool isUsed = eventTicketing.isUsed(ticketId);
        Assert.equal(isUsed, true, "Ticket should be marked as used");
    }

    function getQRCode() public {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        string memory qrCode = eventTicketing.getQRCode(ticketId);
        Assert.equal(qrCode, "QR_CODE_DATA", "QR code should match");
    }
}
