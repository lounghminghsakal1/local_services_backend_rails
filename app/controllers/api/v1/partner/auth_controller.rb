class Api::V1::Partner::AuthController < ApplicationController
  # POST /api/v1/partner/signup   { name, email, password, password_confirmation?, current_lat, current_long }
  def signup
    user = Auth::RegisterPartnerService.new(attributes: signup_params).call
    render_auth_session(user, message: "Partner registered successfully", status: :created)
  end

  # POST /api/v1/partner/login    { email, password }
  def login
    user = Auth::LoginService.new(email: params[:email], password: params[:password], role: "partner").call
    render_auth_session(user, message: "Logged in successfully")
  end

  private

  def signup_params
    params.permit(:name, :email, :password, :password_confirmation, :current_lat, :current_long)
  end
end
