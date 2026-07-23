Given("I am on the homepage") do
  visit root_path
end

When("I look at the page") do
  # noop
end

Then("I should see the application") do
  expect(page).to have_content("Aura")
end
