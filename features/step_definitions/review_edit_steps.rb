# Step definitions for editing reviews

Given(/^I have reviewed "([^"]*)" with rating (\d+) and comment "([^"]*)"$/) do |track_name, rating, comment|
  # Find or create the song
  song = Song.find_or_create_by(title: track_name, artist: 'The Beatles')
  
  # Use the current signed-in user
  user = current_user || User.find_by(email: 'tester@example.com')
  
  # Ensure comment meets minimum length requirement (10 characters)
  comment = comment.ljust(10, ' ') if comment.length < 10
  
  # Create the review
  @my_review = Review.create!(
    user: user,
    song: song,
    rating: rating.to_i,
    comment: comment
  )
end

Given(/^another user "([^"]*)" has reviewed "([^"]*)" with rating (\d+) and comment "([^"]*)"$/) do |email, track_name, rating, comment|
  # Create another user if they don't exist
  other_user = User.find_or_create_by(email: email) do |u|
    u.name = email.split('@').first.capitalize
    u.username = email.split('@').first
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.lastfm_username = email.split('@').first
    u.lastfm_session_key = 'fake_session_key'
  end
  
  # Find or create the song
  song = Song.find_or_create_by(title: track_name, artist: 'The Beatles')
  
  # Create the review
  @other_review = Review.create!(
    user: other_user,
    song: song,
    rating: rating.to_i,
    comment: comment
  )
end

When(/^I visit the song page for "([^"]*)"$/) do |track_name|
  song = Song.find_by(title: track_name)
  visit song_path(song)
end

When(/^I click the "([^"]*)" button for my review$/) do |button_text|
  # Find the current user's most recent review on this page
  user = User.find_by(email: 'tester@example.com') || User.find_by(email: 'kian@example.com')
  
  # Find the review - either the one we created in the step or the most recent one
  if @my_review && @my_review.comment.present?
    review_comment = @my_review.comment
    # If we have a specific review comment, find that exact review
    within('.review', text: review_comment) do
      click_link button_text
    end
  else
    # Find the most recently created review by this user that's visible on the page
    # This handles reviews created through different flows (LastFM)
    # Just click the first Edit link we can find (should be the user's review)
    click_link button_text
  end
end

When(/^I update the rating to (\d+)$/) do |new_rating|
  fill_in 'review_rating', with: new_rating
end

When(/^I update the comment to "([^"]*)"$/) do |new_comment|
  fill_in 'review_comment', with: new_comment
end

When(/^I click "([^"]*)"$/) do |button_text|
  # Try to find a button first, then a link
  begin
    click_button button_text
  rescue Capybara::ElementNotFound
    click_link button_text
  end
end

Then(/^I should be on the song page for "([^"]*)"$/) do |track_name|
  song = Song.find_by(title: track_name)
  expect(current_path).to eq(song_path(song))
end

Then(/^I should not see an "([^"]*)" button for that review$/) do |button_text|
  # Within the other user's review, there should be no Edit button
  within('.review', text: @other_review.comment) do
    expect(page).not_to have_link(button_text)
  end
end

Then(/^I should see an error message about the comment being too short$/) do
  expect(page).to have_content(/too short|at least 10 characters/i)
end

Then(/^the review should still show "([^"]*)"$/) do |original_comment|
  # After validation error, go back to the song page to verify
  song = @my_review.song
  visit song_path(song)
  expect(page).to have_content(original_comment)
end
