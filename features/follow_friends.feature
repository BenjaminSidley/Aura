Feature: Follow and interact with friends
  As a signed-in user
  I want to search for and follow other users
  So that I can connect with people who share my music taste

  Background:
    Given I am signed in as "alice@example.com"
    And I connect my Last.fm account
    And the following users exist:
      | name          | email              | username    |
      | Bob Smith     | bob@example.com    | bob_smith   |
      | Charlie Davis | charlie@example.com| charlie_d   |
      | Diana Prince  | diana@example.com  | diana_p     |

  Scenario: Search for friends by username
    When I visit the friends page
    And I search for friends with "bob"
    Then I should see "Bob Smith" in the search results
    And I should see "bob_smith" in the search results

  Scenario: Search for friends by name
    When I visit the friends page
    And I search for friends with "Charlie"
    Then I should see "Charlie Davis" in the search results

  Scenario: Follow a user
    When I visit the friends page
    And I search for friends with "bob"
    And I click "Follow" for "Bob Smith"
    Then I should see "Now following Bob Smith"
    And I should see "Following" for "Bob Smith"

  Scenario: Unfollow a user
    Given I am following "bob@example.com"
    When I visit the friends page
    And I search for friends with "bob"
    Then I should see "Following" for "Bob Smith"
    When I click "Following" for "Bob Smith"
    Then I should see "Unfollowed Bob Smith"
    And I should see "Follow" for "Bob Smith"

  Scenario: View my following list
    Given I am following "bob@example.com"
    And I am following "charlie@example.com"
    When I visit my profile
    Then I should see "2" users I'm following
    When I click on the following count
    Then I should see "Bob Smith" in the following page
    And I should see "Charlie Davis" in the following page

  Scenario: View a friend's profile and their reviews
    Given "bob@example.com" has reviewed "Stairway to Heaven" with rating 5 and comment "Best rock song ever"
    When I visit the friends page
    And I search for friends with "bob"
    And I click on "Bob Smith"'s profile
    Then I should see "Bob Smith"'s profile page
    And I should see "Stairway to Heaven" on the page
    And I should see "Best rock song ever" on the page

  Scenario: Cannot follow myself
    When I visit the friends page
    Then I should not see my own profile in the list

  Scenario: See music taste compatibility with a friend
    Given I have reviewed "Hey Jude" with rating 5 and comment "Love this song"
    And "bob@example.com" has reviewed "Hey Jude" with rating 5 and comment "Amazing track"
    And I am following "bob@example.com"
    When I visit "bob@example.com"'s profile
    Then I should see "Bob Smith"
    And I should see reviews from "bob@example.com"
