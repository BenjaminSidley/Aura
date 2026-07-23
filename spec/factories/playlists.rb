FactoryBot.define do
  factory :playlist do
    sequence(:title) { |n| "Playlist #{n}" }
    description { "A sample playlist" }
    association :user
  end
end
