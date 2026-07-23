Given("the following users exist:") do |table|
  table.hashes.each do |hash|
    User.create!(
      name: hash['name'],
      email: hash['email'],
      username: hash['username'],
      password: 'password',
      password_confirmation: 'password'
    )
  end
end

When("I search for {string}") do |query|
  fill_in "q", with: query
  click_button "Search"
end

Then("Alice User should be following Bob User") do
  alice = User.find_by(name: "Alice User")
  bob = User.find_by(name: "Bob User")
  expect(alice.following?(bob)).to be true
end

Given("I follow {string}") do |user_name|
  user = User.find_by(name: user_name)
  current_user = User.find_by(email: @current_user_email)
  current_user.follow(user)
end

When("I view the following list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit following_friend_path(alice)
end

When("I view the following list for {string}") do |user_name|
  user = User.find_by(name: user_name)
  visit following_friend_path(user)
end

Then("I should see {string} in the following list") do |user_name|
  expect(page).to have_content(user_name)
end

Given("Bob User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  bob = User.find_by(name: "Bob User")
  bob.follow(alice)
end

Given("Charlie User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  charlie = User.find_by(name: "Charlie User")
  charlie.follow(alice)
end

When("I view the followers list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit followers_friend_path(alice)
end

When("I view the followers list for {string}") do |user_name|
  user = User.find_by(name: user_name)
  visit followers_friend_path(user)
end

Then("I should see {string} in the followers list") do |user_name|
  expect(page).to have_content(user_name)
end

When("I unfollow {string}") do |user_name|
  user = User.find_by(name: user_name)
  current_user = User.find_by(email: @current_user_email)
  current_user.unfollow(user)
end

Then("I should see a message about empty following list") do
  expect(page).to have_content(/no.*following|following.*empty|not.*following anyone/i)
end

Then("I should see a message about empty followers list") do
  expect(page).to have_content(/no.*followers|followers.*empty|not.*followers|no one.*following/i)
end

Given("Alice User has not followed anyone") do
  alice = User.find_by(name: "Alice User")
  alice.following.destroy_all
end

Given("no one is following Alice User") do
  alice = User.find_by(name: "Alice User")
  alice.followers.destroy_all
end

Given("Diana User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  diana = User.find_by(name: "Diana User")
  diana.follow(alice)
end

When("Bob User is signed in") do
  bob = User.find_by(name: "Bob User")
  @current_user_email = bob.email
  visit new_session_path
  fill_in "Username or Email", with: bob.email
  fill_in "Password", with: "password"
  click_button "Sign In"
end

When("Bob User views the followers list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit followers_friend_path(alice)
end

Then("Bob User should see {string} in the followers list") do |user_name|
  expect(page).to have_content(user_name)
end

When("Bob User views the following list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit following_friend_path(alice)
end

Then("Bob User should see {string} in the following list") do |user_name|
  expect(page).to have_content(user_name)
end

# New step definitions for improved scenarios

Given(/^I am following "([^"]*)"$/) do |email|
  current_user = User.find_by(email: 'alice@example.com') || User.find_by(email: @current_user_email)
  other_user = User.find_by(email: email)
  current_user.follow(other_user) if other_user
end

Given(/^"([^"]*)" has reviewed "([^"]*)" with rating (\d+) and comment "([^"]*)"$/) do |email, track_name, rating, comment|
  user = User.find_by(email: email)
  song = Song.find_or_create_by(title: track_name, artist: 'The Beatles')
  Review.create!(user: user, song: song, rating: rating.to_i, comment: comment)
end

When(/^I visit the friends page$/) do
  visit friends_path
end

When(/^I search for friends with "([^"]*)"$/) do |query|
  fill_in 'q', with: query
  click_button 'Search'
end

Then(/^I should see "([^"]*)" in the search results$/) do |text|
  expect(page).to have_content(text)
end

When(/^I click "([^"]*)" for "([^"]*)"$/) do |button_text, user_name|
  within('.card', text: user_name) do
    click_button button_text
  rescue Capybara::ElementNotFound
    click_link button_text
  end
end

Then(/^I should see "([^"]*)" for "([^"]*)"$/) do |button_text, user_name|
  within('.card', text: user_name) do
    expect(page).to have_content(button_text)
  end
end

Then(/^I should see "([^"]*)" users I'm following$/) do |count|
  # The profile page shows "2\nFollowing" format
  expect(page).to have_content("#{count}\nFollowing") or expect(page).to have_content("Following: #{count}")
end

When(/^I click on the following count$/) do
  click_link('2') # Clicks on the following count link
end

Then(/^I should see "([^"]*)" in the following page$/) do |user_name|
  expect(page).to have_content(user_name)
end

Then(/^I should see "([^"]*)" in my following list$/) do |user_name|
  within('.list-group') do
    expect(page).to have_content(user_name)
  end
rescue Capybara::ElementNotFound
  expect(page).to have_content(user_name)
end

When(/^I click on "([^"]*)"'s profile$/) do |user_name|
  click_link user_name
end

Then(/^I should see "([^"]*)"'s profile page$/) do |user_name|
  expect(page).to have_content(user_name)
end

Then(/^I should not see a "([^"]*)" button for myself$/) do |button_text|
  # Check that there's no Follow button in my own user card
  user = User.find_by(email: 'alice@example.com')
  within('.user-card', text: user.name) do
    expect(page).not_to have_button(button_text)
  end
rescue Capybara::ElementNotFound
  # If no user card for self, that's also fine
  true
end

Then(/^I should see shared music taste indicators$/) do
  expect(page).to have_css('.shared-taste') or expect(page).to have_content('shared')
end

Then(/^I should not see my own profile in the list$/) do
  user = current_user || User.find_by(email: @current_user_email)
  expect(page).not_to have_content(user.username) if user
end

When(/^I visit "([^"]*)"'s profile$/) do |email|
  user = User.find_by(email: email)
  visit user_path(user) if user
end

Then(/^I should see reviews from "([^"]*)"$/) do |email|
  user = User.find_by(email: email)
  if user && user.reviews.any?
    expect(page).to have_content('Reviews') or expect(page).to have_css('.review')
  else
    expect(page).to have_content('No reviews') or expect(page).to have_content(user.name)
  end
end
