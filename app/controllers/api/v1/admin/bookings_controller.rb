class Api::V1::Admin::BookingsController < ApplicationController
  def manual_assign
    admin = Admin.find(params[:admin_id])
    booking = Booking.find(params[:id]) # present in url iteself so its :id
    manual_assigned_booking = Bookings::HandleBookingManualAssignService.new(admin: admin, booking: booking, manual_assign_params: params).call
    render_success(data: BookingSerializer.new(manual_assigned_booking).as_json, message: "Booking assigned successfully", status: :ok)
  end

  def broadcast
    admin = Admin.find(params[:admin_id])
    booking = Booking.find(params[:id])
    broadcasted_booking = Bookings::HandleBookingBroadcastService.new(admin: admin, booking: booking).call
    render_success(data: BookingSerializer.new(broadcasted_booking).as_json, message: "Booking broad casted successfully", status: :ok)
  end

  def index
    all_bookings = Booking.where(status: "pending_admin_review")
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
