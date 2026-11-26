class CreatePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners do |t|
      t.references :user, null: false, foreign_key: true
      t.string :current_lat, null: false, precision: 4, scale: 2
      t.decimal :current_long, null: false, precision: 4, scale: 2
      t.timestamp :location_updated_at
      t.integer :status

      t.timestamps
    end
  end
end
