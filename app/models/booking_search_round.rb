class BookingSearchRound < ApplicationRecord
  belongs_to :booking

  enum :status, {
    searching: "searching",
    completed: "completed",
    stopped: "stopped",
    expired: "expired"
  }
end
