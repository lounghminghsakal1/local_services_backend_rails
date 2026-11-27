class User < ApplicationRecord
  has_secure_password # bcrypt: adds password=, password_confirmation= and authenticate; stores the hash in password_digest

  # Applied on save AND in find_by / where, so "  Rahul@Example.COM " finds "rahul@example.com".
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
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
