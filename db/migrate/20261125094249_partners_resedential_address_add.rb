class PartnersResedentialAddressAdd < ActiveRecord::Migration[8.1]
  def change
    add_reference :partners, :residential_address, null: true, foreign_key: { to_table: :addresses }
    add_column :addresses, :latitude, :decimal, null: false, default: 17.29, precision: 10, scale: 6
    add_column :addresses, :longitude, :decimal, null: false, default: 78.29, precision: 10, scale: 6
    add_reference :booking_search_rounds, :booking, null: false, foreign_key: { to_table: :bookings }
    remove_reference :booking_search_rounds, :partner, foreign_key: { to_table: :partners }
  end
end
