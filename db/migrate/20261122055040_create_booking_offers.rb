class CreateBookingOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_offers do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.integer :response
      t.references :assigned_by_admin, null: false, foreign_key: { to_table: :admins }
      t.integer :source
      t.datetime :offered_at
      t.integer :search_radius_km
      t.datetime :expires_at
      t.datetime :responded_at

      t.timestamps
    end
  end
end
