class Api::V1::Partner::BookingOffersController < ApplicationController
  def accept
    partner = Partner.find(params[:partner_id])
    booking_offer = BookingOffer.find(params[:id])
    accepted_booking_offer = BookingOffers::AcceptBookingOfferService.new(partner: partner, booking_offer: booking_offer, booking_offer_accept_params: params).call
    render_success(data: BookingOfferSerializer.new(accepted_booking_offer).as_json, message: "Booking offer accepted successfully")
  end

  def reject
    partner = Partner.find(params[:partner_id])
    booking_offer = BookingOffer.find(params[:id])
    rejected_booking_offer = BookingOffers::RejectBookingOfferService.new(partner: partner, booking_offer: booking_offer).call
    render_success(data: BookingOfferSerializer.new(rejected_booking_offer).as_json, message: "Booking offer rejected successfully")
  end

  def in_progress
    partner = Partner.find(params[:partner_id])
    booking_offer = BookingOffer.find(params[:id])
    in_progress_booking = Bookings::HandleBookingLifecycleService.new(partner: partner, booking_offer: booking_offer).in_progress
    render_success(data: BookingSerializer.new(in_progress_booking).as_json)
  end

  def complete
    partner = Partner.find(params[:partner_id])
    booking_offer = BookingOffer.find(params[:id])
    completed_booking = Bookings::HandleBookingLifecycleService.new(partner: partner, booking_offer: booking_offer).complete
    render_success(data: BookingSerializer.new(completed_booking).as_json)
  end
end


# for accept i think no body is needed just validations are enough like the partner should not be in another work, etc... , handle concurrency also
