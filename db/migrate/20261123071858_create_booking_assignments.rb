class CreateBookingAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_assignments do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.references :booking_offer, null: false, foreign_key: true
      t.string :reason

      t.timestamps
    end
  end
end
