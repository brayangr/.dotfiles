module Async
  module Remunerations
    class SalaryPaymentDraftsController < AsyncController
      def index
        Remuneration::SalaryPaymentDrafts::IndexResponse.call(
          community: current_community,
          employee_finder: params[:employee_finder],
          month: params[:month],
          year: params[:year],
          part_time: false,
          order: params[:order],
          options: { instantiate_context: self }
        )

        respond_to do |format|
          format.html do
            @pagy_employees, @employees = pagy_collection(collection: @employees, param_name: 'page', limit: Constants::Remunerations::PER_PAGE)
            render partial: 'async/remunerations/extra_hours_table'
          end
        end
      end

      def worked_days
        Remuneration::SalaryPaymentDrafts::IndexResponse.call(
          community: current_community,
          employee_finder: params[:employee_finder],
          month: params[:month],
          year: params[:year],
          part_time: true,
          order: params[:order],
          options: { instantiate_context: self }
        )

        respond_to do |format|
          format.html do
            @pagy_employees, @employees = pagy_collection(collection: @employees, param_name: 'page', limit: Constants::Remunerations::PER_PAGE)
            render partial: 'async/remunerations/worked_days_table'
          end
        end
      end
    end
  end
end
