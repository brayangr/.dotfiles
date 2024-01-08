module Admin
  class PaymentsStpDispertionsSupportsController < AdminApplicationController
    # GET /supports
    def index
      @tab = 'payments_stp_supports'
      @community = Community.find(community_params)
      @search_query = search_query_params.strip if search_query_params.present?
      payer_account =  @community.banking_setting.costs_center_clabe
      company = @community.banking_setting.costs_center_name

      begin
        @filter_date = Date.parse(@search_query) if @search_query.present?
      rescue ArgumentError
        @filter_date = nil
      end

      pp "Search_query #{@search_query}"

      @dispertion_payments = DispersedPayment.order_by_dispersion_date
                                             .where("metadata->'message'->'orden_pago'->>'empresa' = ? ", company)
                                             .where("metadata->'message'->'orden_pago'->>'cuenta_ordenante' = ? ", payer_account)
                                             .paginate(page: params[:page], per_page: 30)
      @dispertion_payments.where!(dispersion_date:  @filter_date.beginning_of_day..@filter_date.end_of_day) if @filter_date.present?
      @dispertion_payments.where!(id: DispersedPayment.search(@search_query.to_s)) if @search_query.present? && @filter_date.nil?
    end

    private
    def community_params
      params.require(:community_id)
    end

    def search_query_params
      params[:search_query]
    end
  end
end
