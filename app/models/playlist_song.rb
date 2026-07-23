class PlaylistSong < ApplicationRecord
  belongs_to :playlist
  belongs_to :song

  validates :song_id, uniqueness: { scope: :playlist_id }
end
