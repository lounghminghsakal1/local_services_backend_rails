class BookingSerializer
  def initialize(booking)
    @booking = booking
  end

  def as_json
    {
      id: @booking.id,
      customer_name: @booking.customer.user.name,
      address: {
        address_line: @booking.address.address_line,
        door_no: @booking.address.door_no,
        street: @booking.address.street,
        city: @booking.address.city,
        state: @booking.address.state,
        country: @booking.address.country
      },
      partner: serialize_partner,
      scheduled_at: @booking.scheduled_at,
      duration_mins: @booking.duration_mins,
      description: @booking.description
    }
  end

  private

  def serialize_partner
    return nil unless @booking.partner
    {
      id: @booking.partner.id,
      partner_name: @booking.partner.user.name,
      partner_current_lat: @booking.partner.current_lat,
      partner_current_long: @booking.partner.current_long
    }
  end
end
