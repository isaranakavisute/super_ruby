class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.string :emoji, null: false
      t.integer :price, null: false           # in baht
      t.integer :original_price               # in baht; set when the product is on sale
      t.decimal :rating, precision: 2, scale: 1, null: false, default: 0
      t.integer :sold_count, null: false, default: 0
      t.string :location, null: false

      t.timestamps
    end
    add_index :products, :name, unique: true
    add_index :products, :category
  end
end
