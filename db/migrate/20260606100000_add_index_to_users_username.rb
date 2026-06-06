class AddIndexToUsersUsername < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, :username, algorithm: :concurrently
  end
end
