module Remuneration
  module SalaryPaymentDrafts
    class CreateResponse < BaseResponse
      def post_initialize
        @community = params[:community]
        @create_params = params[:create_params]&.except(:tab)
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

      def instantiate_variables
        super

        @response.add_data(:columns, @columns, instantiable: true) if @tab == :extra_hours
      end
    end
  end
end
