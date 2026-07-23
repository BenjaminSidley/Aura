Feature: Sign up / Login
  As a user
  I want to log in
  So that I can leave reviews

  Scenario: Sign out
    Given I am signed in as "kian@example.com"
    When I sign out
    Then I should see "Sign in"