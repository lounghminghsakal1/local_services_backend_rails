class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :address_line
      t.string :door_no
      t.string :street
      t.string :city
      t.string :state
      t.string :country
      t.boolean :is_default
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
