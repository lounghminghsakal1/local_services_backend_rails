module Bookings
  # Opens the NEXT automatic search round (10 km -> 20 km).
  # If no radius is left, or nobody is eligible in the remaining radii, the customer is asked to decide.
  #
  # Called from Bookings::ExpireSearchRoundService after a round ends without an acceptance.
  #
  # PRECONDITION: the caller is inside a transaction and holds the booking row lock.
  # Returns the new round, or nil when the booking was moved to awaiting_customer_decision.
  class AdvanceSearchService
    RADII_KM = [
      BookingOffer::INITIAL_BOOKING_OFFER_RADIUS_KM,
      BookingOffer::SECOND_BOOKING_OFFER_RADIUS_KM
    ].freeze

    def initialize(booking:, admin: nil)
      @booking = booking
      @admin = admin
    end

    def call
      # Use the biggest radius already tried (not a round count), so this stays correct
      # even when an empty round was skipped.
      last_radius = @booking.booking_search_rounds.maximum(:radius_km) || 0

      RADII_KM.select { |radius| radius > last_radius }.each do |radius|
        round = StartSearchRoundService.new(
          booking: @booking,
          admin: @admin,
          radius_km: radius,
          deadline_at: Booking::SEARCH_ROUND_DURATION.from_now
        ).call

        return round if round # found partners at this radius; the round job is already scheduled
      end

      ask_customer_to_decide
      nil
    end

    private

    def ask_customer_to_decide
      deadline = Booking::CUSTOMER_DECISION_WINDOW.from_now

      @booking.update!(
        status: "awaiting_customer_decision",
        customer_search_decision: "pending",
        customer_search_deadline_at: deadline
      )

      # Same deadline we just saved; the job re-checks the state when it fires.
      CustomerDecisionExpirationJob.set(wait_until: deadline).perform_later(@booking.id)
    end
  end
end
