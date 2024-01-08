module Remuneration
  module SalaryPaymentDrafts
    class CreateResponse < BaseResponse
      def post_initialize
        @community = params[:community]
        @create_params = params[:create_params]
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
