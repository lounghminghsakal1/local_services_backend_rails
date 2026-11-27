class AddBookingReferenceInBookingOffers < ActiveRecord::Migration[8.1]
  def change
    add_reference :booking_offers, :booking_search_rounds, foreign_key: true, null: true

    change_column_null :booking_offers, :assigned_by_admin_id, true

    add_index :booking_offers, [ :booking_id, :response ]
  end
end
