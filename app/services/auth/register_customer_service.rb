module Auth
  # Creates a User (role: customer) and its Customer profile, all or nothing.
  # attributes: name, email, password, password_confirmation (optional)
  # Raises ActiveRecord::RecordInvalid (-> 422 in ApplicationController) if anything is invalid.
  class RegisterCustomerService
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
          role: "customer"
        )
        Customer.create!(user: user)
        user
      end
    end
  end
end
