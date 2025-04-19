class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :category
      t.integer :inventory_count
      t.string :type
      t.string :title
      t.string :author
      t.string :publisher
      t.string :isbn

      t.timestamps
    end
  end
end
