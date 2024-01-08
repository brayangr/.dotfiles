module Remuneration
  module SalaryPaymentDraftsHelper
    def build_filter_params(tab:)
      { tab: tab, month: @month, year: @year, employee_finder: @employee_finder }
    end
  end
end
