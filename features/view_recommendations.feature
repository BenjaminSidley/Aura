Feature: View personalized recommendations
  As a signed-in user with Last.fm connected
  I want to see personalized song recommendations
  So that I can discover new music based on my listening history

  Background:
    Given I am signed in as "music_lover@example.com"
    And I connect my Last.fm account

  Scenario: View recommendations on discover page when Last.fm is connected
    When I visit the discover page
    Then I should see the "Recommended For You" section

  Scenario: Recommendations section is visible
    When I visit the discover page
    Then I should see the "Recommended For You" section
    And I should see "Based on your Last.fm listening history"

  Scenario: Review Recently Played link is visible
    When I visit the discover page
    Then I should see a link to review recently played songs

  Scenario: View profile page
    When I visit my profile
    Then I should see my username

  Scenario: Discover page shows search
    When I visit the discover page
    Then I should see "Search Last.fm"

  Scenario: Discover page layout check
    When I visit the discover page
    Then I should see the "Recommended For You" section

  Scenario: Empty state message visible
    When I visit the discover page
    Then I should see "Loading recommendations" or helper text

  Scenario: Recommendations section exists
    When I visit the discover page
    Then I should see the "Recommended For You" section
