module Remuneration
  module SalaryPaymentDraftsHelper
    def build_filter_params(tab:)
      { tab: :worked_days, month: @month, year: @year, employee_finder: @employee_finder }
    end
  end
end
