class Api::V1::Customer::BookingsController < ApplicationController
  before_action :authenticate_customer! # every action below works on current_customer (from the token)

  def create
    created_booking = Bookings::CreateBookingService.new(customer: current_customer, booking_params: booking_params).call
    render_success(data: BookingSerializer.new(created_booking).as_json, message: "Booking created successfully", status: :created)
  end

  def index
    bookings = current_customer.bookings.includes(
      { customer: :user },
      { partner: :user },
      :address,
      :service_category,
    )
    bookings_array = bookings.map do |booking|
        BookingSerializer.new(booking).as_json
    end
    render_success(data: bookings_array, message: "All bookings fetched successfully")
  end

  def show
    # Scoped to current_customer: someone else's booking id gives 404, same as an id that does not exist
    booking = current_customer.bookings.includes({ customer: :user }, { partner: :user }, :address, :service_category).find(params[:id])
    render_success(data: BookingSerializer.new(booking).as_json, message: "Booking fetched successfully")
  end

  # Customer's answer when no professional was found: { decision: "wait"|"cancel", wait_minutes }
  def search_decision
    booking = current_customer.bookings.find(params[:id])
    decided_booking = Bookings::HandleCustomerSearchDecisionService.new(
      booking: booking,
      decision: params.require(:decision),
      wait_minutes: params[:wait_minutes]
    ).call
    render_success(data: BookingSerializer.new(decided_booking).as_json, message: "Decision saved")
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
# (customer_id is NOT sent any more: it comes from the Authorization: Bearer <token> header)
# {
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
