module Remuneration
  module SalaryPaymentDraftsHelper
    def build_filter_params(tab:, part_time: nil)
      {
        tab: tab,
        month: @month,
        year: @year,
        employee_finder: @employee_finder,
        part_time: part_time
      }
    end

    def extra_hour_columns(employees:, salaries:)

    end
  end
end
