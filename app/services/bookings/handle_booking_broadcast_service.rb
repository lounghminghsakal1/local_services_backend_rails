module Bookings
  class HandleBookingBroadcastService
    def initialize(admin:, booking:)
      @admin = admin
      @booking = booking
    end

    def call
       booking_offer_ids = []
      ApplicationRecord.transaction do
        @booking.lock!
        unless @booking.pending_admin_review?  # Here , this api is admin api , here in this line it checks the booking is already in other status or not so this check can be done by 2 or more admin request so if its concurrently came then
          # then both requests read the same status and proceeds to change it , resulting in duplicate data so we lock the booking so another request wait for the lock to be released and once its free and another request got the data , the booking ststus would have changed to any other which make the another request to return the
          # error response instead of creating new duplicate record
          # so whenever we are updating a record based on checking its status first, its better to acquire a lock
          raise AppError.new("Booking must be at status of pending admin review, but its #{@booking.status}", status: :unprocessable_entity)
        end

        # fetch the partners who are currently not in any work, who are within initial radius defined in search round, who can provide the service that booking requested
        # eligible_partners = find_eligible_partners(10)

        # if eligible_partners.empty?
        #   # no eligible partner is available within 10 km radius so increase radius upto 20km
        #   eligible_partners = find_eligible_partners(20)
        #   if eligible_partners.empty?
        #     eligible_partners = find_eligible_partners(50)
        #     if eligible_partners.empty?
        #       raise AppError.new("No eligible partner is available within 50km radius")
        #     end
        #   end
        # end

        eligible_partners = []
        radius = 10
        while eligible_partners.empty?
          break if radius > 50
          eligible_partners = find_eligible_partners(radius_km: radius)
          radius += 20
        end

        if eligible_partners.empty?
          raise AppError.new("No eligible partner is found within 50km radius", status: :unprocessable_entity)
        end


        # Got eligible partners so send them booking offer and create booking round entry
        eligible_partners.each do |partner|
          created_booking_offer = partner.booking_offers.create!(
            booking: @booking,
            assigned_by_admin: @admin,
            source: "broadcast",
            offered_at: Time.now,
            search_radius_km: radius,
            expires_at: 10.minutes.from_now,
          )
          booking_offer_ids.push(created_booking_offer.id)
        end

        @booking.booking_search_rounds.create!(
          radius_km: radius,
          status: "searching",
          started_at: Time.now,
          deadline_at: 10.minutes.from_now,
        )

        @booking.update!(status: "searching_partner", assignment_mode: "broadcast")
        end

      booking_offer_ids.each do |booking_offer_id|
        BookingOfferExpirationJob.set(wait_until: 10.minutes.from_now).perform_later(booking_offer_id)
      end
      @booking
      end

      private

      def find_eligible_partners(radius_km: 10)
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

        Partner.joins(:partner_services)
                                  .joins("LEFT JOIN addresses residential_addresses ON residential_addresses.id = partners.residential_address_id") # left join keeps left table records (partners) so the partners who have no residential address record but fresh lat, long updates will remain
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
          radius_km: radius_km
        )
        .distinct
      end
  end
end
