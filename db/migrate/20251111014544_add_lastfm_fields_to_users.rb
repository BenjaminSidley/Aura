class AddLastfmFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :lastfm_username, :string
    add_column :users, :lastfm_session_key, :string
    add_column :users, :lastfm_connected, :boolean, default: false

    add_index :users, :lastfm_username, unique: true
  end
end
