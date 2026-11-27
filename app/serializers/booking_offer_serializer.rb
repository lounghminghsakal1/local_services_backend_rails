class BookingOfferSerializer
  def initialize(booking_offer)
    @booking_offer = booking_offer
  end

  def as_json
    {
      id: @booking_offer.id,
      partner: serialize_partner,
      response: @booking_offer.response,
      assigned_by: @booking_offer.assigned_by_admin&.user&.name,
      source: @booking_offer.source,
      offered_at: @booking_offer.offered_at,
      search_radius_km: @booking_offer.search_radius_km,
      responded_at: @booking_offer.responded_at || nil
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
end
