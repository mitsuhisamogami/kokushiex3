class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.references :test, null: false, foreign_key: true
      t.integer :question_number, null: false
      t.string :content, null: false
      t.string :image_url

      t.timestamps
    end
  end
end
