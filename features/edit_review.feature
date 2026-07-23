Feature: Edit an existing review
  As a signed-in user
  I want to edit my previously created reviews
  So that I can update my thoughts or correct mistakes

  Background:
    Given I am signed in as "tester@example.com"
    And I connect my Last.fm account

  Scenario: Edit a review from the song page
    Given I have reviewed "Bohemian Rhapsody" with rating 4 and comment "Good song, quite enjoyable"
    When I visit the song page for "Bohemian Rhapsody"
    Then I should see "Good song, quite enjoyable" on the page
    When I click the "Edit" button for my review
    And I update the rating to 5
    And I update the comment to "Absolutely amazing! A masterpiece of rock music"
    And I click "Update review"
    Then I should see "Review updated successfully"
    And I should see "Absolutely amazing! A masterpiece of rock music" on the page
    And I should not see "Good song, quite enjoyable" on the page

  Scenario: Cancel editing a review
    Given I have reviewed "Yesterday" with rating 3 and comment "Nice classic tune"
    When I visit the song page for "Yesterday"
    And I click the "Edit" button for my review
    And I click "Cancel"
    Then I should be on the song page for "Yesterday"
    And I should see "Nice classic tune" on the page

  Scenario: Cannot edit another user's review
    Given another user "alice@example.com" has reviewed "Let It Be" with rating 5 and comment "Wonderful song"
    When I visit the song page for "Let It Be"
    Then I should not see an "Edit" button for that review

  Scenario: Validation error when editing review with short comment
    Given I have reviewed "Come Together" with rating 4 and comment "Great Beatles track"
    When I visit the song page for "Come Together"
    And I click the "Edit" button for my review
    And I update the comment to "Bad"
    And I click "Update review"
    Then I should see an error message about the comment being too short
    And the review should still show "Great Beatles track"
