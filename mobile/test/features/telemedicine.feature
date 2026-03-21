Feature: Telemedicine Appointment Scheduling

  Scenario: Successful Appointment Booking
    Given I am on the Telemedicine screen
    When I select the specialist {"Dr. Sarah Smith"}
    And I tap {"09:00"} text
    And I tap {"Confirm Appointment"} text
    Then I see {"Appointment booked successfully!"} text

  Scenario: No Available Slots
    Given I am on the Telemedicine screen
    When I select the specialist {"Dr. Busy"}
    Then I see {"No slots available for this date."} text

  Scenario: Conflicting Appointment
    Given I am on the Telemedicine screen
    When I select the specialist {"Dr. Conflict"}
    And I tap {"10:00"} text
    And I tap {"Confirm Appointment"} text
    Then I see {"Failed to book: Conflict"} text

  Scenario: Network Failure During Confirmation
    Given I am on the Telemedicine screen
    When I select the specialist {"Dr. Sarah Smith"}
    And I tap {"09:00"} text
    And the network fails
    And I tap {"Confirm Appointment"} text
    Then I see {"Failed to book: Network connection lost"} text
