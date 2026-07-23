class Playlist < ApplicationRecord
  belongs_to :user
  has_many :playlist_songs, dependent: :destroy
  has_many :songs, through: :playlist_songs

  validates :title, presence: true

  def add_song(song)
    playlist_songs.find_or_create_by(song: song)
  end
end
