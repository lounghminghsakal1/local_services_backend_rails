module BookingOffers
  class RejectBookingOfferService
    def initialize(partner:, booking_offer:)
      @partner = partner
      @booking_offer = booking_offer
    end

    def call
      if @booking_offer.partner_id != @partner.id
        raise AppError.new("You cannot reject this booking offer, this booking offer not belongs to you", status: :unauthorized)
      end

      Booking.transaction do
        booking = Booking.lock.find(@booking_offer.booking_id)
        @booking_offer.lock!
        if booking.assignment_mode == "manual" && booking.status != "awaiting_partner_response"
          raise AppError.new("Booking must be at awaiting partner response status, but its already #{booking.status}", status: :unprocessable_entity)
        end

        if booking.assignment_mode == "broadcast" && booking.status != "searching_partner"
          raise AppError.new("Booking must be at searching_partner status, but its already #{booking.status}", status: :unprocessable_entity)
        end

        unless @booking_offer.pending?
          raise AppError.new("Booking offer must be at pending status, but its already #{@booking_offer.response}", status: :unprocessable_entity)
        end

        # update booking offer
        @booking_offer.update!(response: "rejected", responded_at: Time.now)
        if booking.booking_offers.pending.none?  # no booking offer is pending -> meaning all are rejected or expired or no accpeted so revert back the status to pendin_admin_review so admin can decide
          booking.update!(status: "pending_admin_review")
        end
      end

      @booking_offer
    end
  end
end
