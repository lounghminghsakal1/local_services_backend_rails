class User < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
  validates :password_hash, presence: true
  validates :role, presence: true
  has_one :customer
  has_one :admin
  has_one :partner

  has_many :addresses

  enum :role, {
    customer: "customer",
    partner: "partner",
    admin: "admin"
  }
end
