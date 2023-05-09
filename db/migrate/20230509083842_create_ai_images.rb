class CreateAiImages < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_images do |t|
      t.string :spell, null: false
      t.string :image_url, null: false
      t.timestamps
    end
  end
end
