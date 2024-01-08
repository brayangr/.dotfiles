module Remuneration
  module SalaryPaymentDrafts
    class BaseResponse < StandardServiceObject
      private

      def set_salary_and_employee
        @salary_payment_drafts = { @salary_payment_draft.salary_id => @salary_payment_draft }
        @employee = @salary_payment_draft.salary.employee
        @salaries = { @employee.id => @salary_payment_draft.salary }

        return unless @tab == :licenses

        last_salary_payment = employee.salary_payments.where(nullified: false, validated: true, dias_licencia: 0).joins(:payment_period_expense).order('period_expenses.period desc').first

        last_salary_payment_value = last_salary_payment.present? ? last_salary_payment.total_imponible : 0

        @last_salary_payments = { @employee.id => last_salary_payment_value }
      end

      def instantiate_variables
        @response.add_data(:salary_payment_drafts, @salary_payment_drafts, instantiable: true)
        @response.add_data(:salaries, @salaries, instantiable: true)
        @response.add_data(:employee, @employee, instantiable: true)
        @response.add_data(:tab, @tab, instantiable: true)
        @response.add_data(:columns, @columns, instantiable: true) if @tab == :extra_hours
      end
    end
  end
end
