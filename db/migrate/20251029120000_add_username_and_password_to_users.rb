class AddUsernameAndPasswordToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_column :users, :password_digest, :string

    add_index :users, :username, unique: true, name: 'index_users_on_username_unique'
    add_index :users, :email, unique: true, name: 'index_users_on_email_unique' unless index_exists?(:users, :email)
  end
end