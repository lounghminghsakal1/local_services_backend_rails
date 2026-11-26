class Booking < ApplicationRecord
  belongs_to :customer
  belongs_to :partner, optional: true
  belongs_to :service_category
  belongs_to :address

  has_many :booking_offers
  has_many :booking_assignments
  has_many :booking_search_rounds

  validates :scheduled_at, presence: true
  validates :duration_mins, presence: true, numericality: { greater_than: 0 }

  enum :status, {
    pending_admin_review: "pending_admin_review",
    searching_partner: "searching_partner", # happens when searching for partner in broadcast
    awaiting_customer_decision: "awaiting_customer_decision", # comes when 20mins time is done, so asked user to make a decision (wait or cancel)
    awaiting_partner_response: "awaiting_partner_response", # happens when admin manually assigns a partner, so partner has to make a decision
    confirmed: "confirmed",
    in_progress: "in_progress",
    completed: "completed",
    expired: "expired",
    cancelled: "cancelled",
    partner_not_available: "partner_not_available" # happens when cusotmer opts for wait more but still couldn't get no one within next 2 hrs of customer opted to wait
  }

  enum :assignment_mode, {
    manual: "manual",
    broadcast: "broadcast"
  }

  enum :customer_search_decision, {
    pending: "pending",
    wait: "wait",
    cancel: "cancel",
    expired: "expired"
  }, prefix: :decision

  BOOKING_ASSIGNABLE_STATUS = "pending_admin_review"
end
