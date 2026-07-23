Feature: Connect Last.fm, search and review a track
  As a signed-in user
  I want to connect my Last.fm account, search for a track and create a review
  So that I can save my listening impressions from Last.fm

  Scenario: Sign in, connect Last.fm, search and review
    Given I am signed in as "tester@example.com"
    When I connect my Last.fm account
    And I search Last.fm for "Hey Jude"
    Then I should see "Hey Jude" in the results
    When I click Review for "Hey Jude" and submit a 5 star review with "Amazing track, love it"
    Then I should see "Amazing track, love it" on the song page

  Scenario: Edit a Last.fm review after creating it
    Given I am signed in as "tester@example.com"
    When I connect my Last.fm account
    And I search Last.fm for "Let It Be"
    Then I should see "Let It Be" in the results
    When I click Review for "Let It Be" and submit a 4 star review with "Good song for listening"
    Then I should see "Good song for listening" on the song page
    When I click the "Edit" button for my review
    And I update the comment to "Great song, one of the best Beatles tracks"
    And I click "Update review"
    Then I should see "Review updated successfully"
    And I should see "Great song, one of the best Beatles tracks" on the page
