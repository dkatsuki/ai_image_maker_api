class CreateAiImages < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_images do |t|
      t.string :spell, null: false
      t.integer :width, null: false
      t.integer :height, null: false
      t.string :extension, null: false, default: 'png'
      t.timestamps
    end
  end
end
