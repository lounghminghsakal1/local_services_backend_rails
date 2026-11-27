module Auth
  # Creates and verifies the JWT sent back by signup / login.
  # The token is signed (HS256) with the app's secret_key_base: anyone can READ its payload,
  # but nobody can change it without the secret, and it stops working after TOKEN_LIFETIME.
  class JsonWebToken
    ALGORITHM = "HS256".freeze
    TOKEN_LIFETIME = 24.hours

    def self.encode(user)
      payload = {
        sub: user.id.to_s,        # who the token belongs to
        role: user.role,
        iat: Time.current.to_i,   # issued at
        exp: TOKEN_LIFETIME.from_now.to_i
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Returns the payload (indifferent access) or raises AppError(401) for a bad / expired token.
    def self.decode(token)
      payload, _header = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
      payload.with_indifferent_access
    rescue JWT::ExpiredSignature
      raise AppError.new("Token has expired", status: :unauthorized)
    rescue JWT::DecodeError
      raise AppError.new("Invalid token", status: :unauthorized)
    end

    def self.secret
      Rails.application.secret_key_base
    end
    private_class_method :secret
  end
end
