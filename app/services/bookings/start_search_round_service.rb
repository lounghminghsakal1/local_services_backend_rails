module Bookings
  class StartSearchRoundService
    FRESH_LOCATION_WINDOW = 3.hours
    def initialize(booking:, radius_km:, deadline_at:, admin: nil)
      @booking = booking
      @radius_km = radius_km
      @deadline_at = deadline_at
      @admin = admin
    end

    def call
      partners = eligible_partners.to_a
      return nil if partners.empty?

      now = Time.current
      booking_search_round = @booking.booking_search_rounds.create!(
        radius_km: @radius_km,
        status: "searching",
        started_at: now,
        deadline_at: @deadline_at
      )

      partners.each do |partner|
        booking_search_round.booking_offers.create!(
          booking: @booking,
          partner: partner,
          assigned_by_admin: @admin,
          source: "broadcast",
          offered_at: now,
          search_radius_km: @radius_km,
          expires_at: @deadline_at
        )
      end

      BookingSearchRoundExpirationJob.set(wait_until: @deadline_at).perform_later(booking_search_round.id)
      booking_search_round
    end

    private

    def eligible_partners
      lat  = "CASE WHEN partners.location_updated_at >= :fresh_after THEN partners.current_lat  ELSE residential_addresses.latitude  END"
      long = "CASE WHEN partners.location_updated_at >= :fresh_after THEN partners.current_long ELSE residential_addresses.longitude END"
      distance = <<~SQL.squish
        2 * 6371.0 * ASIN(SQRT(LEAST(1.0, GREATEST(0.0,
          POWER(SIN(RADIANS((:booking_lat - (#{lat})) / 2.0)), 2) +
          COS(RADIANS(:booking_lat)) * COS(RADIANS(#{lat})) *
          POWER(SIN(RADIANS((:booking_long - (#{long})) / 2.0)), 2)))))
      SQL

      already_offered = BookingOffer.where(booking_id: @booking.id).select(:partner_id)

      Partner
        .joins(:partner_services)
        .joins("LEFT JOIN addresses residential_addresses ON residential_addresses.id = partners.residential_address_id")
        .where(partner_services: { service_category_id: @booking.service_category_id, is_active: true })
        .where(is_currently_working: false, status: "active")
        .where.not(id: already_offered)
        .where("(#{distance}) <= :radius_km",
               fresh_after: FRESH_LOCATION_WINDOW.ago,
               booking_lat: @booking.address.latitude,
               booking_long: @booking.address.longitude,
               radius_km: @radius_km)
        .distinct
    end
  end
end
