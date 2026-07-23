class CreateSongsAndMigrateReviews < ActiveRecord::Migration[8.1]
  def up
    create_table :songs do |t|
      t.string :title, null: false
      t.string :artist, null: false
      t.string :album
      t.string :musicbrainz_id
      t.timestamps
    end

    # add nullable song_id to reviews to migrate data
    add_column :reviews, :song_id, :bigint
    add_index :reviews, :song_id

    # Backfill songs from existing albums referenced by reviews
    # Create a song record for each distinct album title+artist and attach reviews
    execute <<~SQL
      INSERT INTO songs (title, artist, album, created_at, updated_at)
      SELECT DISTINCT albums.title AS title, albums.artist AS artist, albums.title AS album, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM albums
      WHERE NOT EXISTS (
        SELECT 1 FROM songs WHERE songs.title = albums.title AND songs.artist = albums.artist
      );
    SQL

    execute <<~SQL
      UPDATE reviews
      SET song_id = songs.id
      FROM songs
      JOIN albums ON albums.title = songs.title AND albums.artist = songs.artist
      WHERE reviews.album_id = albums.id;
    SQL

    # remove foreign key and album_id column
    if foreign_key_exists?(:reviews, :albums)
      remove_foreign_key :reviews, :albums
    end
    remove_column :reviews, :album_id
  end

  def down
    add_column :reviews, :album_id, :bigint
    add_index :reviews, :album_id

    # Attempt to recreate albums from songs and link back; best-effort only
    execute <<~SQL
      INSERT INTO albums (title, artist, created_at, updated_at)
      SELECT DISTINCT title, artist, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM songs
      WHERE NOT EXISTS (
        SELECT 1 FROM albums WHERE albums.title = songs.title AND albums.artist = songs.artist
      );
    SQL

    execute <<~SQL
      UPDATE reviews
      SET album_id = albums.id
      FROM albums
      WHERE reviews.song_id IS NOT NULL AND albums.title = (
        SELECT title FROM songs WHERE songs.id = reviews.song_id LIMIT 1
      ) AND albums.artist = (
        SELECT artist FROM songs WHERE songs.id = reviews.song_id LIMIT 1
      );
    SQL

    remove_index :reviews, :song_id
    remove_column :reviews, :song_id
    drop_table :songs
  end
end
