class AuthSessionSerializer
  def initialize(user:, token:)
    @user = user
    @token = token
  end

  # profile_id is the id the other APIs expect: customer_id, partner_id or admin_id
  def as_json
    {
      token: @token,
      token_type: "Bearer",
      user: {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        role: @user.role
      },
      "#{@user.role}_id": @user.public_send(@user.role).id
    }
  end
end
