module Bookings
  class CreateBookingService
    def initialize(customer:, booking_params:)
      @customer = customer
      @booking_params = booking_params
    end

    def call
      # validate service category
      service_category = ServiceCategory.find(@booking_params[:service_category_id]) # raises ActiveRecord::NoRecordFound error if no record found and its catched by ApplicationController
      address = Address.find_by!(id: @booking_params[:address_id], user_id: @customer.user_id) # raises ActiveRecord::NoRecordFound error if no record found and its catched by ApplicationController

      # create booking record
      Booking.create!(
        customer: @customer,
        service_category: service_category,
        address: address,
        scheduled_at: @booking_params[:scheduled_at],
        duration_mins: @booking_params[:duration_mins],
        description: @booking_params[:description],
        status: :pending_admin_review)
    end
  end
end


# write down payload here also so that it would be easy
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
