FactoryBot.define do
  factory :song do
    sequence(:title) { |n| "Track #{n}" }
    artist { "Unknown Artist" }
    album { "Unknown Album" }
  end
end
