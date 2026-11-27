class Api::V1::Admin::BookingsController < ApplicationController
  before_action :authenticate_admin! # admin endpoints: only a logged-in admin gets in; current_admin comes from the token

  def manual_assign
    booking = Booking.find(params[:id]) # present in url iteself so its :id
    manual_assigned_booking = Bookings::HandleBookingManualAssignService.new(admin: current_admin, booking: booking, manual_assign_params: params).call
    render_success(data: BookingSerializer.new(manual_assigned_booking).as_json, message: "Booking assigned successfully", status: :ok)
  end

  def broadcast
    booking = Booking.find(params[:id])
    broadcasted_booking = Bookings::HandleBookingBroadcastService.new(admin: current_admin, booking: booking).call
    render_success(data: BookingSerializer.new(broadcasted_booking).as_json, message: "Booking broad casted successfully", status: :ok)
  end

  def index
    # includes(...) loads every association the serializer touches in a handful of queries
    # instead of several extra queries per booking; order makes the list order stable.
    all_bookings = Booking.includes({ customer: :user }, { partner: :user }, :address, :service_category)
                          .where(status: "pending_admin_review")
                          .order(:scheduled_at, :id)
    all_bookings_serialized_array = all_bookings.map do |booking|
      BookingSerializer.new(booking).as_json
    end
    render_success(data: all_bookings_serialized_array)
  end

  def show
    booking = Booking.find(params[:id])
    render_success(data: BookingSerializer.new(booking).as_json)
  end
end


# For manual assign -> admin can assign 1 or more partners so for a particular booking
# admin can send multiple partner_id s in body
# {
#   "partner_ids": [1, 2, 4]
# }
#
#
#
