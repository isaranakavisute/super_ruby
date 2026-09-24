# Products moved to the PostgreSQL database (db/postgres/products.sql), so remove the SQLite copy
class DropProductsFromSqlite < ActiveRecord::Migration[8.1]
  def change
    drop_table :products do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.string :emoji, null: false
      t.integer :price, null: false
      t.integer :original_price
      t.decimal :rating, precision: 2, scale: 1, null: false, default: 0
      t.integer :sold_count, null: false, default: 0
      t.string :location, null: false

      t.timestamps
      t.index :name, unique: true
      t.index :category
    end
  end
end
