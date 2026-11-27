# Expires a MANUAL-assign booking offer once its expires_at has passed.
# Broadcast offers are not handled here: they expire together with their search round
# (see BookingSearchRoundExpirationJob).
#
# Scheduled by: Bookings::HandleBookingManualAssignService, one job per offer,
#               with wait_until: offer.expires_at
class BookingOfferExpirationJob < ApplicationJob
  queue_as :default

  def perform(booking_offer_id)
    offer = BookingOffer.find_by(id: booking_offer_id)
    return unless offer
    return unless offer.manual? # broadcast offers expire with their round

    # Woke up before the deadline (clock skew): re-arm instead of silently dropping the alarm.
    if offer.expires_at > Time.current
      self.class.set(wait_until: offer.expires_at + 1.second).perform_later(booking_offer_id)
      return
    end

    ApplicationRecord.transaction do
      # Lock order: booking FIRST, then the offer (same order as accept / reject).
      booking = Booking.lock.find(offer.booking_id)
      offer.lock! # reloads the offer, so the state check below sees fresh data

      next unless offer.pending? # accepted, rejected or closed in the meantime

      offer.update!(response: "expired", responded_at: Time.current)

      # Every partner ignored the offer: give the booking back to the admin.
      if booking.awaiting_partner_response? && booking.booking_offers.pending.none?
        booking.update!(status: "pending_admin_review")
      end
    end
  end
end
