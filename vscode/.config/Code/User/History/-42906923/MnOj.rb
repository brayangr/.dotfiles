module Remuneration
  module DiscountsDraftsHelper
    def causal_options
      Hash[Finiquito.causales.map { |causal| [causal['code'], { name: causal['article'] }]}]
    end
  end
end
