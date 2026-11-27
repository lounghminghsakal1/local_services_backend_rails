class Api::V1::Customer::AuthController < ApplicationController
  # POST /api/v1/customer/signup   { name, email, password, password_confirmation? }
  def signup
    user = Auth::RegisterCustomerService.new(attributes: signup_params).call
    render_auth_session(user, message: "Customer registered successfully", status: :created)
  end

  # POST /api/v1/customer/login    { email, password }
  def login
    user = Auth::LoginService.new(email: params[:email], password: params[:password], role: "customer").call
    render_auth_session(user, message: "Logged in successfully")
  end

  private

  def signup_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
