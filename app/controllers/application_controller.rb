class ApplicationController < ActionController::API
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
rescue_from AppError, with: :handle_app_error
rescue_from ActionController::ParameterMissing, with: :handle_param_missing

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
end
