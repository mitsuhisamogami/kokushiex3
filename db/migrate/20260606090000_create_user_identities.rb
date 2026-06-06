class CreateUserIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :name
      t.string :image_url

      t.timestamps
    end

    add_index :user_identities, %i[provider uid], unique: true
    add_index :user_identities, %i[user_id provider], unique: true
  end
end
