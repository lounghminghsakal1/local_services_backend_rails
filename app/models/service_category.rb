class ServiceCategory < ApplicationRecord
  has_many :partner_services
  has_many :partners, through: :partner_services

  has_many :bookings

  validates :category_name, presence: true
  validates :min_price, presence: true, numericality: { greater_than: 0 }

  enum :category_name, {
    cook: "cook",
    maid: "maid",
    electrician: "electrician",
    plumber: "plumber",
    painter: "painter"
  }
end
