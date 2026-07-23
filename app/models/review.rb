class Review < ApplicationRecord
  belongs_to :user
  belongs_to :song

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true, length: { minimum: 10 }
  validates :user_id, uniqueness: { scope: :song_id, message: "has already reviewed this song" }
end
