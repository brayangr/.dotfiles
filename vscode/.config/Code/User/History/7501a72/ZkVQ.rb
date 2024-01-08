module Remuneration
  module SalaryPaymentDrafts
    class ResetResponse < BaseResponse
      def post_initialize
        @salary_payment_draft = SalaryPaymentDraft.find(params[:salary_payment_draft_id])
        @tab = params[:tab]
      end

      def call
        byebug
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
      end
    end
  end
end
