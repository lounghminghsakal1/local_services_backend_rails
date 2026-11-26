class FixPartnerCoordinatesAndNullableBookingPartner < ActiveRecord::Migration[8.1]
  def change
    # 1. Allow bookings to be created before a partner is assigned
    change_column_null :bookings, :partner_id, true

    # 2. Expand current_long to standard GPS precision (-180.000000 to 180.000000)
    change_column :partners, :current_long, :decimal, precision: 10, scale: 6

    # (Optional) Convert current_lat from string to matching decimal so distance math works cleanly
    change_column :partners, :current_lat, :decimal, precision: 10, scale: 6, using: "current_lat::numeric"
  end
end
