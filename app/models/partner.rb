class Partner < ApplicationRecord
  belongs_to :user
  has_many :partner_services
  has_many :service_categories, through: :partner_services
  has_many :booking_offers
  has_many :booking_assignments
  has_many :bookings
  belongs_to :residential_address, class_name: "Address", optional: true

  validates :current_lat, presence: true
  validates :current_long, presence: true


  enum :status, {
    active: "active",
    inactive: "inactive"
  }
end
