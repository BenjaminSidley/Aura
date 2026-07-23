class CreatePlaylistsAndPlaylistSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :playlists do |t|
      t.string :title, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :published_to_lastfm, default: false, null: false
      t.string :lastfm_playlist_id
      t.timestamps
    end

    create_table :playlist_songs do |t|
      t.references :playlist, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.integer :position
      t.timestamps
    end

    add_index :playlist_songs, [:playlist_id, :song_id], unique: true
  end
end
