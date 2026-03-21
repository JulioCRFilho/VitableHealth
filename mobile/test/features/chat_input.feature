Feature: Chat Input Sanity

Scenario: Trim and Validate whitespace-only messages
  Given I am on the Chat screen
  When I enter {"   "} into the message input
  And I tap the Send button
  Then I should see {1} messages in the chat list

Scenario: Handle UTF-8 and Emojis
  Given I am on the Chat screen
  When I enter {"Test 🧪 ⚡ 漢字"} into the message input
  And I tap the Send button
  Then I should see {3} messages in the chat list
  And I should see {"Test 🧪 ⚡ 漢字"} in the chat list
