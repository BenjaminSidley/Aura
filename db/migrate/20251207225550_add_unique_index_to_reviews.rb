class AddUniqueIndexToReviews < ActiveRecord::Migration[8.1]
  def up
    # First, remove duplicate reviews, keeping only the most recent one for each user-song pair
    execute <<-SQL
      DELETE FROM reviews
      WHERE id NOT IN (
        SELECT MAX(id)
        FROM reviews
        GROUP BY user_id, song_id
      );
    SQL
    
    # Now add the unique index
    add_index :reviews, [:user_id, :song_id], unique: true, name: 'index_reviews_on_user_and_song'
  end

  def down
    remove_index :reviews, name: 'index_reviews_on_user_and_song'
  end
end
