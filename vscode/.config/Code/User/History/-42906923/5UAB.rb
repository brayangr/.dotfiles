module Remuneration
  module DiscountsDraftsHelper
    def reasons_options
      byebug
      Hash[DiscountsDraft.reasons.map { |reason| [reason, { name: t("views.remunerations.salary_payment_drafts.discounts_days.#{reason}") }] }]
    end
  end
end
