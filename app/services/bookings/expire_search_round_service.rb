module Bookings
  # Closes a search round that nobody accepted, then moves the booking to its next step.
  #
  # Called from:
  #   * BookingSearchRoundExpirationJob  (the round's deadline passed)
  #   * RejectBookingOfferService        (every offer of the round was answered, no need to wait)
  #
  # PRECONDITION: the caller is inside a transaction, holds the booking row lock
  #               (Booking.lock.find) and has called round.lock! (so both objects are fresh).
  class ExpireSearchRoundService
    def initialize(booking:, round:)
      @booking = booking
      @round = round
    end

    def call
      # Already handled: a partner accepted (round "completed"), the booking was cancelled,
      # or a duplicate / late job fired. Doing nothing here is what makes the job safe to run twice.
      return unless @round.searching? && @booking.searching_partner?

      now = Time.current

      # 1. Offers share the round's deadline, so every still-pending offer of this round expires now.
      @round.booking_offers.pending.update_all(response: "expired", responded_at: now, updated_at: now)

      # 2. Close the round.
      @round.update!(status: "expired", completed_at: now)

      # 3. What happens next.
      if @booking.decision_wait?
        # This was the customer's one-time extended search: no second chance.
        @booking.update!(status: "partner_not_available")
      else
        # Round 1 -> round 2 (20 km), or round 2 -> ask the customer to decide.
        Bookings::AdvanceSearchService.new(booking: @booking).call
      end
    end
  end
end
