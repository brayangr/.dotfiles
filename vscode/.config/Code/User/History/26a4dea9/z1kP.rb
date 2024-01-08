module Remuneration
  module SalaryPaymentDrafts
    class WorkedDaysResponse < StandardServiceObject
      def post_initialize
        @community = params[:community]
      end

      def call
        set_dates
        set_employees
        set_salaries
        set_salary_payment_drafts
        instantiate_variables
      end

      private

      def salaries_ids
        @salaries_ids ||= @employees.map(&:salary_id)
      end

      def set_dates
        # TODO: define according to filter
        @start_date = Date.today.beginning_of_month
        @end_date = Date.today.end_of_month
        @payment_period_expense = @community.get_period_expense(Date.today.month, Date.today.year)
      end

      def set_employees
        @employees = Remunerations::SalaryPaymentDraftsQueries.employees(
          community_id: @community.id, start_date: @start_date, end_date: @end_date
        )
      end

      def set_salaries
        @salaries = Salary
          .where(id: salaries_ids)
          .index_by(&:employee_id)
      end

      def set_salary_payment_drafts
        @salary_payment_drafts = SalaryPaymentDraft
          .where(payment_period_expense_id: @payment_period_expense.id, salary_id: salaries_ids)
          .index_by(&:salary_id)
      end

      def instantiate_variables
        @response.add_data(:index, :worked_days, instantiable: true)
        @response.add_data(:payment_period_expense, @payment_period_expense, instantiable: true)
        @response.add_data(:employees, @employees, instantiable: true)
        @response.add_data(:salaries, @salaries, instantiable: true)
        @response.add_data(:salary_payment_drafts, @salary_payment_drafts, instantiable: true)
      end
    end
  end
end
