module Auth
  # Creates a User (role: partner) and its Partner profile, all or nothing.
  # attributes: name, email, password, password_confirmation (optional), current_lat, current_long
  # A partner needs a location at signup because partners.current_lat / current_long cannot be NULL.
  class RegisterPartnerService
    def initialize(attributes:)
      @attributes = attributes
    end

    def call
      ApplicationRecord.transaction do
        user = User.create!(
          name: @attributes[:name],
          email: @attributes[:email],
          password: @attributes[:password],
          password_confirmation: @attributes[:password_confirmation],
          role: "partner"
        )
        Partner.create!(
          user: user,
          current_lat: @attributes[:current_lat],
          current_long: @attributes[:current_long],
          location_updated_at: Time.current,
          status: "active" # DECISION: new partners can receive offers immediately. Use "inactive" to require approval.
        )
        user
      end
    end
  end
end
