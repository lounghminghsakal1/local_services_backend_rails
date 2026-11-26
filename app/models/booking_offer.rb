class BookingOffer < ApplicationRecord
  belongs_to :booking
  belongs_to :partner
  belongs_to :assigned_by_admin, class_name: "Admin", optional: true

  enum :response, {
    pending: "pending",
    accepted: "accepted",
    rejected: "rejected",
    expired: "expired",
    closed: "closed"
  }

  enum :source, {
    manual: "manual",
    broadcast: "broadcast"
  }

  INITIAL_BOOKING_OFFER_RADIUS_KM = 10
  SECOND_BOOKING_OFFER_RADIUS_KM = 20
  EXTENDED_BOOKING_OFFER_RADIUS_KM = 50
end
