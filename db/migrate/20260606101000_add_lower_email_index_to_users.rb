class AddLowerEmailIndexToUsers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, 'LOWER(email)', name: 'index_users_on_lower_email', algorithm: :concurrently
  end
end
