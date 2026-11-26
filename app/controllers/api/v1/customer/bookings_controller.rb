class Api::V1::Customer::BookingsController < ApplicationController
  def create
    customer = Customer.find(params[:customer_id]) # find will throw error if no customer found, thrown error will be catched in ApplicationController
    created_booking = Bookings::CreateBookingService.new(customer: customer, booking_params: booking_params).call
    render_success(data: BookingSerializer.new(created_booking).as_json, message: "Booking created successfully", status: :created)
  end

  def index
    bookings = Booking.includes(
      { customer: :user },
      { partner: :user },
      :address,
      :service_category,
    ).where(customer_id: params[:customer_id])
    bookings_array = bookings.map do |booking|
        BookingSerializer.new(booking).as_json
    end
    render_success(data: bookings_array, message: "All bookings fetched successfully")
  end

  def show
    booking = Booking.includes({ customer: :user }, { partner: :user }, :address, :service_category).find_by!(id: params[:id], customer_id: params[:customer_id])
    render_success(data: BookingSerializer.new(booking).as_json, message: "Booking fetched successfully")
  end

  private

  def booking_params
    params.require("booking").permit("service_category_id", "address_id", "scheduled_at", "duration_mins", "description")
  end
end




# ok, first write down the booking create api payload then it will be easy
# so for that first list down the needed field to create a booking , by seeing schema.rb
# needed fields -> customer_id, service_category_id, address_id, scheduled_at, duration_mins, description
# yeah these above fields are required fields to create boooking in db
# Now find out from where we are going to get these fields (data),
# customer_id got from logged in customer and other fields are customer has to select because the booking is for customer , so this booking is mainly revolving around customer
# so now write down the request payload
# {
# customer_id:   -> here customer_id got from authenticated user but i didn't write authentication yet so this approach for now
# booking: {
#   service_category_id:
#   address_id:
#   scheduled_at:
#   duration_mins:
#   description:
# }
# }
#
#
