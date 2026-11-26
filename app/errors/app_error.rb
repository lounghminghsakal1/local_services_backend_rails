class AppError < StandardError
  attr_reader :status
  def initialize(message = "Something wrong", status: :internal_server_error)
    @status = status
    super(message)
  end
end
