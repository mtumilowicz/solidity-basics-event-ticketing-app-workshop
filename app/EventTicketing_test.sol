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

    /// #value: 1000000000000000
    function buyTicket() public payable {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        eventTicketing.buyTicket{value: ticketPrice}(ticketId);
        bool purchased = eventTicketing.isPurchased(ticketId);
        Assert.equal(purchased, true, "Ticket should be purchased");
    }

    /// #value: 1000000000000000
    function validateTicket() public payable {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        eventTicketing.buyTicket{value: ticketPrice}(ticketId);
        eventTicketing.validateTicket(ticketId);
        bool isUsed = eventTicketing.isUsed(ticketId);
        Assert.equal(isUsed, true, "Ticket should be marked as used");
    }

    function validateNonExistingTicket() public payable {
        try eventTicketing.validateTicket(10) {
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Invalid ticket ID', 'failed with unexpected reason');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
    }

    function getQRCode() public {
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        string memory qrCode = eventTicketing.getQRCode(ticketId);
        Assert.equal(qrCode, "QR_CODE_DATA", "QR code should match");
    }
}
