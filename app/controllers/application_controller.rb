class ApplicationController < ActionController::API
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
rescue_from AppError, with: :handle_app_error
rescue_from ActionController::ParameterMissing, with: :handle_param_missing
rescue_from ActiveRecord::RecordNotUnique, with: :handle_not_unique

def handle_not_found(exception)
  render_failure(errors: exception.message, message: "Not found", status: :not_found)
end

def handle_invalid_record(exception)
  render_failure(errors: exception.record.errors.full_messages, message: "Invalid request", status: :unprocessable_entity)
end

def handle_app_error(exception)
  render_failure(errors: exception.message, message: "App error", status: exception.status)
end

def handle_param_missing(exception)
  render_failure(errors: exception.message, message: "Missing params", status: :unprocessable_entity)
end

def handle_not_unique(exception)
  # Two signups with the same email at the same moment both pass the model's uniqueness check;
  # the unique index in the database stops the second one and we answer it like a normal validation error.
  render_failure(errors: [ "A record with these details already exists" ], message: "Invalid request", status: :unprocessable_entity)
end

def render_success(data:, message: "Action successfull", status: :ok)
  render json: {
    status: "success",
    data: data,
    errors: nil,
    message: message
  }, status: status
end

def render_failure(errors: nil, message: "Action unsuccessfull", status: :unprocessable_entity)
  render json: {
    status: "failure",
    data: nil,
    errors: errors,
    message: message
  }, status: status
end

private

# Used by signup / login: wraps the user and a fresh JWT in the standard success response.
def render_auth_session(user, message:, status: :ok)
  token = Auth::JsonWebToken.encode(user)
  render_success(data: AuthSessionSerializer.new(user: user, token: token).as_json, message: message, status: status)
end

# Reads the header  Authorization: Bearer <token>, verifies it and sets current_user.
# 401 = no token / bad token / expired token / the user no longer exists.
def authenticate_user!
  token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
  raise AppError.new("Missing or malformed Authorization header", status: :unauthorized) if token.blank?

  payload = Auth::JsonWebToken.decode(token)
  @current_user = User.find_by(id: payload[:sub]) || raise(AppError.new("User not found", status: :unauthorized))
end

def current_user
  @current_user
end

# Role gates. Use one per controller:  before_action :authenticate_customer!
# They log the request in AND check the account type, then expose the profile record:
# current_customer / current_partner / current_admin. These replace customer_id / partner_id /
# admin_id coming from the request, which anybody could fake.
# 403 = logged in, but the wrong kind of account for this endpoint.
def authenticate_customer!
  @current_customer = authenticate_role!("customer")
end

def authenticate_partner!
  @current_partner = authenticate_role!("partner")
end

def authenticate_admin!
  @current_admin = authenticate_role!("admin")
end

def current_customer
  @current_customer
end

def current_partner
  @current_partner
end

def current_admin
  @current_admin
end

# The role is read from the DATABASE (current_user.role), not from the token's "role" claim,
# so an old token cannot keep a role the account no longer has.
def authenticate_role!(role)
  authenticate_user!

  unless current_user.role == role
    raise AppError.new("This endpoint is only available to #{role} accounts", status: :forbidden)
  end

  current_user.public_send(role) || raise(AppError.new("No #{role} profile found for this account", status: :forbidden))
end
end
