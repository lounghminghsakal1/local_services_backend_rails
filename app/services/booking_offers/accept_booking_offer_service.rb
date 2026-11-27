module BookingOffers
  class AcceptBookingOfferService
    def initialize(partner:, booking_offer:, booking_offer_accept_params:)
      @partner = partner
      @booking_offer = booking_offer
      @params = booking_offer_accept_params
    end

    def call
      # This authorization check is based on id column which is immutable column,
      # so its an immediate check based on immutable column so we can put it outside lock
      # # 1. Fast-fail immutable checks outside the transaction
      if @booking_offer.partner_id != @partner.id
        raise AppError.new("You cannot accept this booking offer", status: :forbidden)
      end

      # started transaction here itself because we are going to acquire locks to prevent race conditions
      # handling concurrency -> many partners can tap on accept button at the same time
      # so one request must lock the rows its dealing with so that we can ensure one req is processed and then
      # second request processes , so in this case 1st req locks the rows , meanwhile second request waits for the locks to be released
      # so now first request marks the booking offer as accepted now locks are released and second request acquire locks on the rows now
      # now it sees the booking offer status as accepted because first request did it so it returns
      # In order to prevent deadlock conditions we must maintain same locking order in entire codebase so make it as a reusable function
      # once transaction commits or any exceptions happen locks are released
      ApplicationRecord.transaction do
        # 2. Acquire locks FIRST in a consistent order (Booking -> Partner -> BookingOffer)
        booking = Booking.lock.find(@booking_offer.booking_id)  # here it fetches and locks in a single query so no extra db round trips
        @partner.lock! # no other requests can read, update , write to this row now
        @booking_offer.lock! # no other requests can read, update , write to this row now

        # 3. Validate mutable state AFTER locks are held
        if @booking_offer.expires_at <= Time.now
          raise AppError.new("Booking offer already expired", status: :unprocessable_entity)
        end

        # check booking is not assigned yet or not
        if booking.assignment_mode == "manual" && booking.status != "awaiting_partner_response"
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
        # 4. Perform updates
        @booking_offer.update!(response: "accepted", responded_at: Time.now)
        booking.update!(status: "confirmed", partner: @partner)
        @partner.update!(is_currently_working: true)
        if @booking_offer.source == "broadcast"
          booking.booking_search_rounds.searching.update_all(status: "completed", completed_at: Time.now)
        end
        booking.booking_offers.pending.where.not(id: @booking_offer.id).update_all(response: "closed", updated_at: Time.current)
        BookingAssignment.create!(booking: booking, partner: @partner, booking_offer: @booking_offer)
      end

      @booking_offer
    end
  end
end
