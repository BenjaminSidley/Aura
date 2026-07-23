Given("I am on the sign up page") do
  visit new_user_path
end

When("I sign up with {string} and {string}") do |name, email|
  fill_in "Full Name", with: name
  fill_in "Email", with: email
  fill_in "Username", with: (email.split('@').first || "user#{rand(1000)}")
  fill_in "Password", with: "password"
  fill_in "Confirm Password", with: "password"
  click_button "Create Account"
end

Then("I should see {string}") do |text|
  expect(page).to have_text(/#{Regexp.escape(text)}/i)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_text(/#{Regexp.escape(text)}/i)
end

Given("I am signed in as {string}") do |email|
  user = User.find_by(email: email) || User.create!(name: "Test User", username: (email.split('@').first), email: email, password: "password", password_confirmation: "password")
  @current_user_email = email
  @current_user = user  # Set current user for helper
  visit new_session_path
  fill_in "Username or Email", with: user.email
  fill_in "Password", with: "password"
  click_button "Sign In"
end


When("I sign out") do
  click_button "Sign Out"
end