module Remuneration
  module SalaryPaymentDrafts
    class UpdateResponse < BaseResponse
      def post_initialize
        @community = params[:community]
        @salary_payment_draft = params[:salary_payment_draft]
        @update_params = params[:update_params]
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
        @salary_payment_draft.update(@update_params)
      end
    end
  end
end
