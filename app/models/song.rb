class Song < ApplicationRecord
  has_many :reviews, dependent: :destroy
  validates :title, :artist, presence: true

  # Returns the average rating for this song as a float rounded to 2 decimals.
  # Returns nil if there are no reviews.
  def average_rating
    avg = reviews.average(:rating)
    return nil unless avg
    avg.to_f.round(2)
  end
end
