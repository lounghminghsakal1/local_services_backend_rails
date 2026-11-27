module BookingOffers
  class RejectBookingOfferService
    def initialize(partner:, booking_offer:)
      @partner = partner
      @booking_offer = booking_offer
    end

    def call
      if @booking_offer.partner_id != @partner.id
        raise AppError.new("You cannot reject this booking offer, this booking offer not belongs to you", status: :forbidden)
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
        if booking.assignment_mode == "broadcast"
          # Broadcast: when the whole round has been answered there is no reason to wait for its timer.
          # The service closes the round and moves on (20 km round / ask the customer / partner_not_available).
          round = @booking_offer.booking_search_round
          if round && round.booking_offers.pending.none?
            round.lock!
            Bookings::ExpireSearchRoundService.new(booking: booking, round: round).call
          end
        elsif booking.booking_offers.pending.none?
          # Manual: no booking offer is pending -> all are rejected or expired, so give the booking back
          # to the admin (pending_admin_review) so the admin can decide.
          booking.update!(status: "pending_admin_review")
        end
      end

      @booking_offer
    end
  end
end
