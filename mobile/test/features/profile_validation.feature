Feature: Profile Validation

  Scenario: Name should be required
    Given I am on the Profile screen
    When I tap the {"Edit Profile Details"} button
    And I enter {""} into the {"Enter your full name"} field
    And I tap the {"Save"} button
    Then I should see the {"Name is required"} error message

  Scenario: Email should be valid
    Given I am on the Profile screen
    When I tap the {"Edit Profile Details"} button
    And I enter {"invalid-email"} into the {"Enter your email address"} field
    And I tap the {"Save"} button
    Then I should see the {"Enter a valid email"} error message

  Scenario: Successful profile update
    Given I am on the Profile screen
    When I tap the {"Edit Profile Details"} button
    And I enter {"John Doe"} into the {"Enter your full name"} field
    And I enter {"john@example.com"} into the {"Enter your email address"} field
    And I tap the {"Save"} button
    Then I should see the {"Profile updated!"} message
