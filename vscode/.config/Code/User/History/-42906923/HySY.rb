module Remuneration
  module DiscountsDraftsHelper
    def causal_options
      Hash[Constants::DiscountsDraft::REASONS.map { |reason| [reason[0], { name: reason[1] }] }]
    end
  end
end
