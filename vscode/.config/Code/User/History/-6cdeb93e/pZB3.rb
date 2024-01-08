module Remuneration
  module SalaryPaymentDrafts
    class UpdateResponse < BaseResponse
      def post_initialize
        @create_params = params[:update_params]
        @tab = params[:tab]
        @columns = params[:columns]
      end

      def call
        byebug
        update_salary_payment_draft
        set_salary_and_employee
        instantiate_variables
      end

      private

      def update_salary_payment_draft
        @salary_payment_draft.update(@create_params)
      end
    end
  end
end
