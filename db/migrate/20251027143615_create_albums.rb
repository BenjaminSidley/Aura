class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string :title
      t.string :artist
      t.integer :year

      t.timestamps
    end
  end
end
