module Auth
  # Checks email + password for ONE role ("customer", "partner" or "admin") and returns the User.
  # Every failure raises the SAME 401 message, so an attacker cannot tell whether the email exists,
  # the password was wrong, or the account belongs to another role.
  class LoginService
    INVALID_CREDENTIALS = "Invalid email or password".freeze

    def initialize(email:, password:, role:)
      @email = email.to_s
      @password = password.to_s
      @role = role.to_s
    end

    def call
      user = User.find_by(email: @email)

      raise invalid_credentials unless user
      raise invalid_credentials unless user.role == @role
      raise invalid_credentials unless password_matches?(user)
      raise invalid_credentials unless user.public_send(@role) # the Customer / Partner / Admin profile must exist

      user
    end

    private

    def password_matches?(user)
      user.authenticate(@password).present?
    rescue BCrypt::Errors::InvalidHash
      false # a row whose password_digest is not a bcrypt hash (old placeholder data)
    end

    def invalid_credentials
      AppError.new(INVALID_CREDENTIALS, status: :unauthorized)
    end
  end
end
