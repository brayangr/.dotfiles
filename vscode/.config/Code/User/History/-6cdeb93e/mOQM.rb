module Remuneration
  module SalaryPaymentDrafts
    class UpdateResponse < BaseResponse
      def post_initialize
        @community = params[:community]
        @create_params = params[:update_params]
        @tab = params[:tab]
        @columns = params[:columns]
      end

      def call
        create_salary_payment_draft
        set_salary_and_employee
        instantiate_variables
      end

      private

      def create_salary_payment_draft
        @salary_payment_draft = SalaryPaymentDraft.create(@create_params)
      end
    end
  end
end
