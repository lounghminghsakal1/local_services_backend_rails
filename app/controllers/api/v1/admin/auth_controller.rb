class Api::V1::Admin::AuthController < ApplicationController
  # Admins cannot sign up through the API: they are created by hand (seeds / console).
  # POST /api/v1/admin/login    { email, password }
  def login
    user = Auth::LoginService.new(email: params[:email], password: params[:password], role: "admin").call
    render_auth_session(user, message: "Logged in successfully")
  end
end
