require 'capybara/rails'
require 'capybara/rspec'

Capybara.default_driver = :selenium
Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.include Capybara::DSL
end
