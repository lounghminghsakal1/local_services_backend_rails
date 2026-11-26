module Bookings
  class HandleBookingManualAssignService
    def initialize(admin:, booking:, manual_assign_params:)
      @admin = admin
      @booking = booking
      @params = manual_assign_params
    end

    def call
      # check booking is in correct status or not
      if @booking.status != Booking::BOOKING_ASSIGNABLE_STATUS # "pending_admin_review"
        raise AppError.new("Booking which is in pending admin review status only can be assigned, currently the booking is #{@booking.status}",

                            status: :unprocessable_entity)
      end

      # check all passed partners are eligible or not
      partner_ids = Array(@params[:partner_ids]).map(&:to_i).uniq
      if partner_ids.empty?
        raise AppError.new("At least one partner is required", status: :unprocessable_entity)
      end

      parnters = Partner.includes(:partner_services, :user).where(id: partner_ids)

      missing_ids = partner_ids - parnters.map(&:id)

      unless missing_ids.empty?
        raise AppError.new("These partner ids are not found, missing: #{missing_ids.join(", ")}")
      end

      inactive_partners = parnters.reject do |partner|
        partner.status == "inactive"
      end

      unless inactive_partners.empty?
        raise AppError.new("These partners are inactive, inactive: #{inactive_partners.map(&:user.name)}")
      end

      parnters.each do |partner|
        is_elgible = partner.partner_services.any? do |ps|
          ps.service_category_id == @booking.service_category_id && ps.is_active
        end
        unless is_elgible
          raise AppError.new("This partner #{partner.user.name} cannot provide this service that the booking requires", status: :unprocessable_entity)
        end
        if partner.is_currently_working
          raise AppError.new("This parnter #{partner.user.name} is currently working in another booking", status: :unprocessable_entity)
        end
      end

      # All validations are passed so send booking offer and update booking status
      Booking.transaction do
        parnters.each do |partner|
        partner.booking_offers.create!(
          booking: @booking,
          assigned_by_admin_id: @admin.id,
          source: "manual",
          offered_at: Time.now,
          expires_at: 10.minutes.from_now,
        )
      end

      @booking.update!(status: "awaiting_partner_response", assignment_mode: "manual")
      end

      @booking
    end
  end
end


# For manual assign -> admin can assign 1 or more partners so for a particular booking
# admin can send multiple partner_id s in body
# {
#   "partner_ids": [1, 2, 4]
# }
