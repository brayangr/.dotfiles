module Remuneration
  module SalaryPaymentDrafts
    class ResetResponse < StandardServiceObject
      def post_initialize
        @salary_payment_draft = SalaryPaymentDraft.find(params[:salary_payment_draft_id])
        @tab = params[:tab]
      end

      def call
        case @tab
        when :worked_days
          reset_worked_days
        end

        set_salary_and_employee
        instantiate_variables
      end

      private

      def reset_worked_days
        @salary_payment_draft.update(worked_days: 0, bono_days: 0)
        @salary_payment_drafts = { @salary_payment_draft.salary_id => @salary_payment_draft }
      end

      def set_salary_and_employee
        @employee = @salary_payment_draft.salary.employee
        @salaries = { @employee.id => @salary_payment_draft.salary }
      end

      def instantiate_variables
        @response.add_data(:salary_payment_drafts, @salary_payment_drafts, instantiable: true)
        @response.add_data(:salaries, @salaries, instantiable: true)
        @response.add_data(:employee, @employee, instantiable: true)
      end
    end
  end
end
