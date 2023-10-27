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

    function testOrganizer() public {
        Assert.equal(eventTicketing.organizer(), address(this), "Organizer should be this contract");
    }

    function testTicketPrice() public {
        Assert.equal(eventTicketing.ticketPrice(), ticketPrice, "Ticket price should be 0.001 ETH");
    }

    function testCreateTicket() public {
        // given
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");

        // when
        string memory qrCode = eventTicketing.getQRCode(ticketId);

        // then
        Assert.equal(qrCode, "QR_CODE_DATA", "QR code should match");
    }

    /// #value: 1000000000000000
    function testBuyTicket() public payable {
        // given
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");

        // when
        eventTicketing.buyTicket{value: ticketPrice}(ticketId);

        // then
        bool purchased = eventTicketing.isPurchased(ticketId);
        Assert.equal(purchased, true, "Ticket should be purchased");
    }

    /// #value: 1000000000000000
    function testValidateTicket() public payable {
        // given
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");
        eventTicketing.buyTicket{value: ticketPrice}(ticketId);

        // when
        eventTicketing.validateTicket(ticketId);

        // then
        bool isUsed = eventTicketing.isUsed(ticketId);
        Assert.equal(isUsed, true, "Ticket should be marked as used");
    }

    function testValidateNonExistingTicket() public payable {
        try eventTicketing.validateTicket(10) {
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Invalid ticket ID', 'failed with unexpected reason');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
    }

    function testGetQRCode() public {
        // given
        uint256 ticketId = eventTicketing.createTicket("QR_CODE_DATA");

        // when
        string memory qrCode = eventTicketing.getQRCode(ticketId);

        // then
        Assert.equal(qrCode, "QR_CODE_DATA", "QR code should match");
    }
}
