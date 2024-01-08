module Remuneration
  module DiscountsDraftsHelper
    def reasons_options
      Hash[DiscountsDraft.reasons.map { |reason| [reason[0], { name: t("views.remunerations.salary_payment_drafts.discounts_days.#{reason}") }] }]
    end
  end
end
