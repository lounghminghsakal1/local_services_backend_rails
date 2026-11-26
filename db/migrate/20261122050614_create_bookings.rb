class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.references :service_category, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.timestamp :scheduled_at, null: false
      t.integer :duration_mins, null: false
      t.string :description
      t.integer :assignment_mode
      t.integer :status
      t.integer :customer_search_decision
      t.datetime :customer_search_deadline_at
      t.datetime :customer_decided_at
      t.datetime :extended_search_deadline_at

      t.timestamps
    end
  end
end
