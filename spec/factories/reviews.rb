FactoryBot.define do
  factory :review do
    rating { 1 }
    comment { "MyText" }
    user { nil }
    song { nil }
  end
end
