module Bookings
  class HandleBookingBroadcastService
    def initialize(admin:, booking:)
      @admin = admin
      @booking = booking
    end

    def call
      unless @booking.pending_admin_review?
        raise AppError.new("Booking must be at status of pending admin review, but its #{@booking.status}", status: :unprocessable_entity)
      end

      fresh_after = 3.hours.ago

      partner_lat_sql = <<~SQL
        CASE#{' '}
        WHEN partners.location_updated_at >= :fresh_after
        THEN partners.current_lat
        ELSE residential_addresses.latitude
        END
      SQL

      partner_long_sql = <<~SQL
        CASE#{' '}
        WHEN partners.location_updated_at >= :fresh_after
        THEN partners.current_long
        ELSE residential_addresses.longitude
        END
      SQL

      booking_lat = @booking.address.latitude
      booking_long = @booking.address.longitude

distance_sql = <<~SQL
  (
    2 * 6371.0 * ASIN(
      SQRT(
        LEAST(
          1.0,
          GREATEST(
            0.0,
            POWER(
              SIN(
                RADIANS(
                  (:booking_lat - (#{partner_lat_sql})) / 2.0
                )
              ), 2
            )
            +
            COS(RADIANS(:booking_lat))
            *
            COS(RADIANS(#{partner_lat_sql}))
            *
            POWER(
              SIN(
                RADIANS(
                  (:booking_long - (#{partner_long_sql})) / 2.0
                )
              ), 2
            )
          )
        )
      )
    )
  )
SQL


      # fetch the partners who are currently not in any work, who are within initial radius defined in search round, who can provide the service that booking requested
      eligible_partners = Partner.joins(:partner_services)
                                  .joins(:resedential_address)
                                  .where(
                                    partner_services: {
                                      service_category_id: @booking.service_category_id,
                                      is_active: true
                                    }
                                  )
                                  .where(is_currently_working: false, status: "active")
                                    .where(
          "#{partner_lat_sql} IS NOT NULL AND
           #{partner_long_sql} IS NOT NULL",
          fresh_after: fresh_after
        )
        .where(
          "#{distance_sql} <= :radius_km",
          fresh_after: fresh_after,
          booking_lat: booking_lat,
          booking_long: booking_long,
          radius_km: 10
        )
        .distinct

        ActiveRecord::Base.transaction do
        # Got eligible partners so send them booking offer and create booking round entry
        eligible_partners.each do |partner|
          partner.booking_offers.create!(
            booking: @booking,
            assigned_by_admin: @admin,
            source: "broadcast",
            offered_at: Time.now,
            search_radius_km: 10,
            expires_at: 10.minutes.from_now,
          )
        end

        @booking.booking_search_rounds.create!(
          radius_km: 10,
          status: "searching",
          started_at: Time.now,
          deadline_at: 10.minutes.from_now,
        )

        @booking.update(status: "searching_partner", assignment_mode: "broadcast")
        end

        @booking
    end
  end
end
