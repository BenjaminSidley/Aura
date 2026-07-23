# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_07_225550) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string "artist"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "year"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "follower_id", null: false
    t.bigint "following_id", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "following_id"], name: "index_follows_on_follower_id_and_following_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.index ["following_id"], name: "index_follows_on_following_id"
  end

  create_table "playlist_songs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "playlist_id", null: false
    t.integer "position"
    t.bigint "song_id", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id", "song_id"], name: "index_playlist_songs_on_playlist_id_and_song_id", unique: true
    t.index ["playlist_id"], name: "index_playlist_songs_on_playlist_id"
    t.index ["song_id"], name: "index_playlist_songs_on_song_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "lastfm_playlist_id"
    t.boolean "published_to_lastfm", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_playlists_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "rating"
    t.bigint "song_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["song_id"], name: "index_reviews_on_song_id"
    t.index ["user_id", "song_id"], name: "index_reviews_on_user_and_song", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "solid_cache_entries", id: false, force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "songs", force: :cascade do |t|
    t.string "album"
    t.string "artist", null: false
    t.datetime "created_at", null: false
    t.string "musicbrainz_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "lastfm_connected", default: false
    t.string "lastfm_session_key"
    t.string "lastfm_username"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email_unique", unique: true
    t.index ["lastfm_username"], name: "index_users_on_lastfm_username", unique: true
    t.index ["username"], name: "index_users_on_username_unique", unique: true
  end

  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "follows", "users", column: "following_id"
  add_foreign_key "playlist_songs", "playlists"
  add_foreign_key "playlist_songs", "songs"
  add_foreign_key "playlists", "users"
  add_foreign_key "reviews", "users"
end
