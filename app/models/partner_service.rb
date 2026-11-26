class PartnerService < ApplicationRecord
  belongs_to :partner
  belongs_to :service_category
end
