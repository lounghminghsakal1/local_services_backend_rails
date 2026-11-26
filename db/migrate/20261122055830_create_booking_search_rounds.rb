class CreateBookingSearchRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_search_rounds do |t|
      t.references :partner, null: false, foreign_key: true
      t.integer :radius_km
      t.integer :status
      t.datetime :started_at
      t.datetime :deadline_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
