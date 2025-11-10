class AddGuestLimitReachedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :guest_limit_reached_at, :datetime
    add_index :users, :guest_limit_reached_at
  end
end
