module Remuneration
  module SalaryPaymentDrafts
    class CreateResponse < StandardServiceObject
      private

      def create_salary_payment_draft
        @salary_payment_draft = SalaryPaymentDraft.create(@create_params)
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
