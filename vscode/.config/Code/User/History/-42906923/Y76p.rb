module Remuneration
  module DiscountsDraftsHelper
    def reasons_options
      Hash[Constants::DiscountsDraft::REASONS.map { |reason| [reason[0].to_i, { name: reason[1] }] }]
    end
  end
end
