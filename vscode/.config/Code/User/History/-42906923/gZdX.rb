module Remuneration
  module DiscountsDraftsHelper
    def causal_options
      Constants::DiscountsDraft::REASONS
      Hash[Finiquito.causales.map { |causal| [causal['code'], { name: causal['article'] }]}]
    end
  end
end
