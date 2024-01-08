module Remuneration
  module DiscountsDraftsHelper
    def reasons_options
      Hash[DiscountsDraft.reasons.except('custom_discount').map { |reason| [reason[0], { name: t("views.remunerations.salary_payment_drafts.discounts_days.reasons.#{reason[0]}") }] }]
    end
  end
end
