Feature: View profile last.fm artists
  In order to see my listening habits
  As a logged in user
  I want to view my profile and see my top Last.fm artists

  Background:
    Given I am signed in as "tester@example.com"

  Scenario: See top Last.fm artists on profile
    Given I connect my Last.fm account
    And Last.fm returns recent tracks including "Radiohead"
    When I visit my profile
    Then I should see "Radiohead"
