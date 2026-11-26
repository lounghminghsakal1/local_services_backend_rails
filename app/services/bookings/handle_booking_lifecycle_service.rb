module Bookings
  class HandleBookingLifecycleService
    def initialize(partner:, booking_offer:)
      @partner = partner
      @booking_offer = booking_offer
    end

    def in_progress
      if @booking_offer.response != "accepted"
        raise AppError.new("Booking offer is not in accepted status", status: :unprocessable_entity)
      end

      booking = Booking.find(@booking_offer.booking_id)
      booking.with_lock do
        unless booking.confirmed?
          raise AppError.new("Booking is not in confirmed to status, so cannot make it in_progress", status: :unprocessable_entity)
        end

        if booking.partner_id != @partner.id
          raise AppError.new("You cannot acces this booking", status: :unprocessable_entity)
        end

        if @partner.is_currently_working
          raise AppError.new("You are in another work", status: :unprocessable_entity)
        end

        booking.update(status: "in_progress")
        @partner.update(is_currently_working: true)
      end
      booking
    end

    def complete
      if @booking_offer.response != "accepted"
        raise AppError.new("Booking offer is not in accepted status", status: :unprocessable_entity)
      end

      booking = Booking.find(@booking_offer.booking_id)
      booking.with_lock do
        unless booking.in_progress?
          raise AppError.new("Booking is not in in progress status, so cannot make it in_progress", status: :unprocessable_entity)
        end

        if booking.partner_id != @partner.id
          raise AppError.new("You cannot access this booking", status: :unprocessable_entity)
        end

        if @partner.is_currently_working
          raise AppError.new("You are in another work", status: :unprocessable_entity)
        end

        booking.update(status: "completed")
        @partner.update(is_currently_working: false)
      end
      booking
    end
  end
end
