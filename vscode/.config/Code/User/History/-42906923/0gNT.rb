module Remuneration
  module DiscountsDraftsHelper
    def reasons_options
      DiscountsDraft.reasons.map { |reason| [reason, { name: t("views.remunerations.salary_payment_drafts.discounts_days.#{reason}") }] }
      Hash[Constants::DiscountsDraft::REASONS.map { |reason| [reason[0].to_i, { name: reason[1] }] }]
    end
  end
end
