class BookingSearchRound < ApplicationRecord
  belongs_to :booking
  has_many :booking_offers

  enum :status, {
    searching: "searching",
    completed: "completed",
    stopped: "stopped",
    expired: "expired"
  }
end
