class BookingOfferSerializer
  def initialize(booking_offer)
    @booking_offer = booking_offer
  end

  def as_json
    {
      id: @booking_offer.id,
      booking_id: @booking_offer.booking_id,
      partner: serialize_partner,
      response: @booking_offer.response,
      assigned_by: @booking_offer.assigned_by_admin&.user&.name,
      source: @booking_offer.source,
      offered_at: @booking_offer.offered_at,
      expires_at: @booking_offer.expires_at,
      search_radius_km: @booking_offer.search_radius_km,
      responded_at: @booking_offer.responded_at || nil,
      booking: serialize_booking
    }
  end

  private

  def serialize_partner
    {
      id: @booking_offer.partner.id,
      partner_name: @booking_offer.partner.user.name,
      current_lat: @booking_offer.partner.current_lat,
      current_long: @booking_offer.partner.current_long
    }
  end

  # What a partner needs to decide on an offer. The customer's name and full address are only
  # shared once THIS partner has accepted the job (plan: do not expose more customer personal
  # information than necessary before acceptance).
  def serialize_booking
    booking = @booking_offer.booking
    summary = {
      id: booking.id,
      status: booking.status,
      service: booking.service_category.category_name,
      scheduled_at: booking.scheduled_at,
      duration_mins: booking.duration_mins,
      description: booking.description,
      city: booking.address.city
    }

    if @booking_offer.accepted?
      summary[:customer_name] = booking.customer.user.name
      summary[:address] = {
        address_line: booking.address.address_line,
        door_no: booking.address.door_no,
        street: booking.address.street,
        city: booking.address.city,
        state: booking.address.state,
        country: booking.address.country
      }
    end

    summary
  end
end
