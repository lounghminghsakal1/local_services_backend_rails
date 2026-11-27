class Api::V1::Partner::BookingOffersController < ApplicationController
  before_action :authenticate_partner! # every action below works on current_partner (from the token)

  # Everything the offer serializer touches, loaded up front so a list costs a fixed number of queries
  OFFER_INCLUDES = [ { assigned_by_admin: :user }, { booking: [ :service_category, :address, { customer: :user } ] } ].freeze

  # GET /api/v1/partner/booking_offers            -> my offers, newest first
  # GET /api/v1/partner/booking_offers?response=pending   (pending | accepted | rejected | expired | closed)
  def index
    if params[:response].present? && !BookingOffer.responses.key?(params[:response].to_s)
      raise AppError.new("response must be one of: #{BookingOffer.responses.keys.join(', ')}", status: :unprocessable_entity)
    end

    offers = current_partner.booking_offers.includes(*OFFER_INCLUDES).order(offered_at: :desc, id: :desc)
    offers = offers.where(response: params[:response].to_s) if params[:response].present?

    render_success(data: offers.map { |offer| BookingOfferSerializer.new(offer).as_json }, message: "Booking offers fetched successfully")
  end

  # GET /api/v1/partner/booking_offers/:id
  def show
    offer = current_partner.booking_offers.includes(*OFFER_INCLUDES).find(params[:id])
    render_success(data: BookingOfferSerializer.new(offer).as_json, message: "Booking offer fetched successfully")
  end

  def accept
    accepted_booking_offer = BookingOffers::AcceptBookingOfferService.new(partner: current_partner, booking_offer: find_offer, booking_offer_accept_params: params).call
    render_success(data: BookingOfferSerializer.new(accepted_booking_offer).as_json, message: "Booking offer accepted successfully")
  end

  def reject
    rejected_booking_offer = BookingOffers::RejectBookingOfferService.new(partner: current_partner, booking_offer: find_offer).call
    render_success(data: BookingOfferSerializer.new(rejected_booking_offer).as_json, message: "Booking offer rejected successfully")
  end

  def in_progress
    in_progress_booking = Bookings::HandleBookingLifecycleService.new(partner: current_partner, booking_offer: find_offer).in_progress
    render_success(data: BookingSerializer.new(in_progress_booking).as_json)
  end

  def complete
    completed_booking = Bookings::HandleBookingLifecycleService.new(partner: current_partner, booking_offer: find_offer).complete
    render_success(data: BookingSerializer.new(completed_booking).as_json)
  end

  private

  # Only the logged-in partner's own offers: another partner's offer id gives 404, same as an id that does not exist
  def find_offer
    current_partner.booking_offers.find(params[:id])
  end
end


# for accept i think no body is needed just validations are enough like the partner should not be in another work, etc... , handle concurrency also
