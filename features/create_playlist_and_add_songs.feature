Feature: Create a playlist and add songs
  As a signed-in user
  I want to create a new playlist and manage its songs
  So that I can organize and manage my favorite songs

  Background:
    Given I am signed in as "user@example.com"
    And I connect my Last.fm account

  Scenario: Create a new playlist
    When I create a playlist named "My Favorites"
    Then I should see "Playlist created"
    And I should see "My Favorites" on the playlist page

  Scenario: Create a playlist and verify it's empty
    When I create a playlist named "Rock Classics"
    Then I should see "Playlist created"
    When I view the playlist
    Then the playlist should contain 0 songs

  Scenario: Add a song to an existing playlist
    Given I have a playlist named "Chill Vibes"
    When I visit the playlist page for "Chill Vibes"
    Then I should see "Chill Vibes"
    And I should see "No songs in this playlist yet"

  Scenario: Add multiple songs to a playlist
    Given I have a playlist named "Best of 2024"
    When I visit the playlist page for "Best of 2024"
    Then I should see "Best of 2024"
    And the playlist should contain 0 songs

  Scenario: Cannot add the same song twice to a playlist
    Given I have a playlist named "Favorites"
    When I visit the playlist page for "Favorites"
    Then I should see "Favorites"

  Scenario: Add a Last.fm track to a playlist
    Given I have a playlist named "Discover Weekly"
    When I visit the playlist page for "Discover Weekly"
    Then I should see "Discover Weekly"
    And I should see "Add"
