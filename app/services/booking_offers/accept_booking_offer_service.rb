module BookingOffers
  class AcceptBookingOfferService
    def initialize(partner:, booking_offer:, booking_offer_accept_params:)
      @partner = partner
      @booking_offer = booking_offer
      @params = booking_offer_accept_params
    end

    def call
      if @booking_offer.partner_id != @partner.id
        raise AppError.new("You cannot accept this booking offer", status: :unauthorized)
      end

      if @booking_offer.expires_at >= Time.now
        raise AppError.new("Booking offer already expired", status: :unprocessable_entity)
      end

      # check booking is not assigned yet or not
      booking = Booking.find(@booking_offer.booking_id)
      if booking.assingment_mode == "manual" && booking.status != "awaiting_partner_response"
        raise AppError.new("Booking status should be awaiting_partner_response but its already in #{booking.status}", status: :unprocessable_entity)
      end

      if booking.assignment_mode == "broadcast" && booking.status != "searching_partner"
        raise AppError.new("Booking status should be searching_partner but its already in #{booking.status}", status: :unprocessable_entity)
      end

      unless @booking_offer.pending?
        raise AppError.new("Booking offer must be at pending status, but its already #{@booking_offer.response}",  status: :unprocessable_entity)
      end

      if @partner.is_currently_working
        raise AppError.new("You are currently in working status, so cannot accept another booking offer", status: :unprocessable_entity)
      end

      can_provide_service = @partner.partner_services.any? do |ps|
        ps.service_category_id == booking.service_category_id && ps.is_active
      end

      unless can_provide_service
        raise AppError.new("Requested service is not in your services list so you cannot provide this service", status: :unprocessable_entity)
      end

      # all validations passed so we can update the booking offer and booking and create booking assignment record
      ActiveRecord::Base.transaction do
        @booking_offer.update!(response: "accepted", responded_at: Time.now)
        booking.update!(status: "confirmed", partner: @partner)
        @partner.update!(is_currently_working: true)
        if @booking_offer.source == "broadcast"
          booking.booking_search_rounds.update_all!(completed_at: Time.now)
        end
        booking.booking_offers.update_all!()
        BookingAssignment.create!(booking: booking, partner: @partner, booking_offer: @booking_offer)
      end
      @booking_offer
    end
  end
end
