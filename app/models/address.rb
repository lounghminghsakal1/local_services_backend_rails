class Address < ApplicationRecord
  belongs_to :user

  has_many :bookings

  validates :address_line, presence: true
  validates :door_no, presence: true
  validates :street, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :country, presence: true
  attribute :country, :string, default: "India"
end
