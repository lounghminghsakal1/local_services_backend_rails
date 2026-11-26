class BookingOfferExpirationJob < ApplicationJob
  queue_as :default

  def perform(booking_offer_id)
    # Do something later
    booking_offer = BookingOffer.find_by(id: booking_offer_id)

    booking_offer.lock!

    return unless booking_offer

    return unless booking_offer.pending?

    return unless booking_offer.booking.searching_partner? || booking_offer.booking.awaiting_partner_response?

    return unless booking_offer.expires_at > Time.now

    booking_offer.update(response: "expired", responded_at: Time.now)
  end
end
