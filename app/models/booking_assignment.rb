class BookingAssignment < ApplicationRecord
  belongs_to :booking
  belongs_to :partner
  belongs_to :booking_offer
end
