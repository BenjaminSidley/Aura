FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Test User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "testuser#{n}" }
    password { "password123" }
  end
end
