class CreateServiceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :service_categories do |t|
      t.integer :category_name
      t.string :description
      t.decimal :min_price

      t.timestamps
    end
  end
end
