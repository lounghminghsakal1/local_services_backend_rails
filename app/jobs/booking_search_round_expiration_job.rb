# Fires when a broadcast search round reaches its deadline_at (round 1: 10 min, round 2: 10 min,
# extended round: the customer's chosen wait time). The round's offers share the same expiry,
# so they are expired together with the round.
#
# Scheduled by: Bookings::StartSearchRoundService, right after it creates the round,
#               with wait_until: round.deadline_at
#
# This job only takes the locks. The decisions (expire offers, close the round, open the next
# round / ask the customer / partner_not_available) live in Bookings::ExpireSearchRoundService.
class BookingSearchRoundExpirationJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = BookingSearchRound.find_by(id: round_id)
    return unless round # the transaction that created the round rolled back

    # Woke up before the deadline (clock skew): re-arm instead of silently dropping the alarm.
    if round.deadline_at > Time.current
      self.class.set(wait_until: round.deadline_at + 1.second).perform_later(round_id)
      return
    end

    ApplicationRecord.transaction do
      # Lock order: booking FIRST (same as accept / reject), then the round.
      booking = Booking.lock.find(round.booking_id)
      round.lock! # reloads status: if a partner accepted meanwhile, the service sees "completed" and does nothing
      Bookings::ExpireSearchRoundService.new(booking: booking, round: round).call
    end
  end
end
