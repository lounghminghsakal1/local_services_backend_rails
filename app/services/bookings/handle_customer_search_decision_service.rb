module Bookings
  # The customer's answer to "we couldn't find a professional nearby":
  #   decision "cancel"                      -> booking is cancelled
  #   decision "wait" + wait_minutes (10-120) -> one-time 50 km search that ends after wait_minutes
  class HandleCustomerSearchDecisionService
    def initialize(booking:, decision:, wait_minutes: nil)
      @booking = booking
      @decision = decision.to_s
      @wait_minutes = wait_minutes.to_i # nil / junk -> 0, rejected by the range check below
    end

    def call
      validate_input!

      ApplicationRecord.transaction do
        @booking.lock! # reloads the booking, so the checks below see fresh data

        unless @booking.awaiting_customer_decision? && @booking.decision_pending?
          raise AppError.new("Booking is not waiting for a decision (status: #{@booking.status})", status: :unprocessable_entity)
        end

        deadline = @booking.customer_search_deadline_at
        if deadline.nil? || deadline <= Time.current
          raise AppError.new("The time to decide is over", status: :unprocessable_entity)
        end

        @decision == "cancel" ? cancel_booking : start_extended_search
      end

      @booking
    end

    private

    def validate_input!
      unless %w[wait cancel].include?(@decision)
        raise AppError.new("decision must be 'wait' or 'cancel'", status: :unprocessable_entity)
      end

      if @decision == "wait" && !@wait_minutes.between?(Booking::MIN_EXTRA_WAIT_MINS, Booking::MAX_EXTRA_WAIT_MINS)
        raise AppError.new(
          "wait_minutes must be between #{Booking::MIN_EXTRA_WAIT_MINS} and #{Booking::MAX_EXTRA_WAIT_MINS}",
          status: :unprocessable_entity
        )
      end
    end

    def cancel_booking
      @booking.update!(
        status: "cancelled",
        customer_search_decision: "cancel",
        customer_decided_at: Time.current
      )
    end

    def start_extended_search
      now = Time.current
      deadline = now + @wait_minutes.minutes # round deadline AND every offer's expires_at

      @booking.update!(
        status: "searching_partner",
        customer_search_decision: "wait",
        customer_decided_at: now,
        extended_search_deadline_at: deadline
      )

      round = StartSearchRoundService.new(
        booking: @booking,
        radius_km: BookingOffer::EXTENDED_BOOKING_OFFER_RADIUS_KM,
        deadline_at: deadline
      ).call

      # Nobody new within 50 km: there is nothing to wait for.
      @booking.update!(status: "partner_not_available") if round.nil?
    end
  end
end
