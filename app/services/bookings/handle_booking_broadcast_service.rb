module Bookings
  class HandleBookingBroadcastService
    def initialize(admin:, booking:)
      @admin = admin
      @booking = booking
    end

    def call
      ApplicationRecord.transaction do
        @booking.lock!
        unless @booking.pending_admin_review?  # Here , this api is admin api , here in this line it checks the booking is already in other status or not so this check can be done by 2 or more admin request so if its concurrently came then
          # then both requests read the same status and proceeds to change it , resulting in duplicate data so we lock the booking so another request wait for the lock to be released and once its free and another request got the data , the booking ststus would have changed to any other which make the another request to return the
          # error response instead of creating new duplicate record
          # so whenever we are updating a record based on checking its status first, its better to acquire a lock
          raise AppError.new("Booking must be at status of pending admin review, but its #{@booking.status}", status: :unprocessable_entity)
        end

        # fetch the partners who are currently not in any work, who are within initial radius defined in search round, who can provide the service that booking requested
        # eligible_partners = find_eligible_partners(10)

        # if eligible_partners.empty?
        #   # no eligible partner is available within 10 km radius so increase radius upto 20km
        #   eligible_partners = find_eligible_partners(20)
        #   if eligible_partners.empty?
        #     eligible_partners = find_eligible_partners(50)
        #     if eligible_partners.empty?
        #       raise AppError.new("No eligible partner is available within 50km radius")
        #     end
        #   end
        # end

        # eligible_partners = []
        # radius = 10
        # while eligible_partners.empty?
        #   break if radius > 50
        #   eligible_partners = find_eligible_partners(radius_km: radius)
        #   radius += 20
        # end

        round = StartSearchRoundService.new(
          booking: @booking,
          admin: @admin,
          radius_km: BookingOffer::INITIAL_BOOKING_OFFER_RADIUS_KM,
          deadline_at: Booking::SEARCH_ROUND_DURATION.from_now
        ).call

        # Nobody eligible: raising rolls everything back, the booking stays pending_admin_review
        raise AppError.new("No eligible partner found within #{BookingOffer::INITIAL_BOOKING_OFFER_RADIUS_KM} km", status: :unprocessable_entity) if round.nil?

        @booking.update!(status: "searching_partner", assignment_mode: "broadcast")
      end

      @booking
    end
  end
end
