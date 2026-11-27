# Fires when the customer's decision window (Booking::CUSTOMER_DECISION_WINDOW, 30 min) ends.
# If the customer still hasn't answered, the booking expires.
#
# Scheduled by: Bookings::AdvanceSearchService#ask_customer_to_decide,
#               with wait_until: booking.customer_search_deadline_at
#
# Stray runs are harmless: if the customer already chose wait/cancel, the state check below
# makes the job do nothing, so scheduled jobs never need to be cancelled.
class CustomerDecisionExpirationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    ApplicationRecord.transaction do
      booking = Booking.lock.find_by(id: booking_id)
      next unless booking && booking.awaiting_customer_decision? && booking.decision_pending?

      deadline = booking.customer_search_deadline_at
      if deadline && deadline > Time.current # woke up early (clock skew): re-arm
        self.class.set(wait_until: deadline + 1.second).perform_later(booking_id)
        next
      end

      booking.update!(status: "expired", customer_search_decision: "expired")
      # TODO: enqueue a "customer decision expired" notification once notifications exist
    end
  end
end
