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
        extra_hour: false,
        extra_hour_2: true,
        extra_hour_3: true
      }

      employees.pluck(:id).each do |employee|
        salary = salaries[employee]
        show[:extra_hour] = true if salary.additional_hour_price.positive?
        byebug
      end
    end
  end
end
