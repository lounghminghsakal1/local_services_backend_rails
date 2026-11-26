class AddressTableChanges < ActiveRecord::Migration[8.1]
  def change
    change_column_null :addresses, :address_line, false, "Example line"
    change_column_null :addresses, :door_no, false, "Example line"
    change_column_null :addresses, :street, false, "Example line"
    change_column_null :addresses, :city, false, "Example line"
    change_column_null :addresses, :state, false, "Example line"
    change_column_default :addresses, :country, from: nil, to: "India"

    change_column_null :service_categories, :category_name, false, "Example category name"
    change_column_null :service_categories, :min_price, false, 200

    add_check_constraint :service_categories, "min_price > 0", name: "category_min_price_check"

    change_column_default :bookings, :status, from: nil, to: "pending_admin_review"

    change_column_default :booking_offers, :response, from: nil, to: "pending"
  end
end
