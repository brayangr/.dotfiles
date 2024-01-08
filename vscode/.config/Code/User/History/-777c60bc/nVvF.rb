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
      show = {
        extra_hour: true,
        extra_hour_2: false,
        extra_hour_3: false
      }

      employees.each do |employee|
        salary = salaries[employee.id]
        show[:extra_hour] = true if salary.additional_hour_price.positive?
        show[:extra_hour_2] = true if salary.additional_hour_price_2.positive?
        show[:extra_hour_3] = true if salary.additional_hour_price_3.positive?
      end

      show
    end
  end
end
