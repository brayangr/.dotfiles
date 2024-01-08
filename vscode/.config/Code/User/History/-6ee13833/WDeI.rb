# frozen_string_literal: true

# Controlador para manejo de FinkokResponses
class FinkokResponsesController < ApplicationController
  load_and_authorize_resource

  before_action :set_finkok_response, only: %i[show]

  def show
    respond_to do |format|
      format.pdf do
        if @finkok_response.payment_receipt?
          redirect_to @finkok_response.invoiceable.receipt.expiring_url(10)
        elsif (@finkok_response.payment? || @finkok_response.complemento?) && @finkok_response.pdf.present?
          redirect_to @finkok_response.pdf.expiring_url(10)
        else
          redirect_back(fallback_location: root_path, notice: t('views.finkok_response.show.notice_no_pdf'))
        end
      end
      format.xml do
        send_data @finkok_response&.xml, filename: "pago_#{@finkok_response.uuid[0..12]}.xml", type: 'application/xml'
      end
    end
  end

  def cancel_irs_bill
    finkok_response = FinkokResponse.find_by(id: cancel_params[:finkok_response_id])
    folio = finkok_response&.folio
    notice = finkok_response.complemento? ? I18n.t('jobs.cancel_irs_bill.complement', folio: folio) : I18n.t('jobs.cancel_irs_bill.bill', folio: folio)

    byebug
    finkok_response.finkok_parent.cancelling_complement! if finkok_response.complemento?

    CancelIrsBillJob.perform_later(user_id:       current_user.id,
                                   cancel_params: cancel_params,
                                   _community_id: current_community.id,
                                   _message:      notice)

    return redirect_to(payments_path(current_tab: 'nullified_tab'), notice: notice) if request.referer.include?(payments_path)

    if params[:property_id].present?
      property = Property.where(id: params[:property_id]).first

      if property.present? && request.referer.include?(payments_property_path(property))
        return redirect_to(payments_property_path(property, current_tab: 'nullified'), notice: notice)
      end
    end

    redirect_back(fallback_location: root_path, notice: notice)
  end

  def check_if_replacement_folio_valid
    return render json: { validInput: false } if params[:folio] == params[:currentFolio]

    global = ActiveModel::Type::Boolean.new.cast(params[:global])
    folio = params[:folio]

    result = if global
               FinkokResponse.by_global_folio(current_community.id, folio)
             else
               current_community.payments
                 .includes(:finkok_response)
                 .not_adjustment
                 .where(irs_billed: true, finkok_responses: { cancelled: false })
                 .where('payments.folio = ?', folio.to_i)
             end

    render json: { validInput: result.present? }
  end

  def cancelled
    @title = I18n.t('mx_companies.irs_billed_cancelled.title')
    @finkok_responses =
      FinkokResponsesQueries
        .cancelled_by_community(community_id: current_community.id)
        .preload(finkok_response_payments: :property)
    @payments = Payment.where(id: @finkok_responses.map(&:invoiceable_id)).preload(:property).index_by(&:id)

    filter if params[:filter].present?

    @pagy_finkok_responses, @finkok_responses = pagy_collection(collection: @finkok_responses,
                                                                param_name: :page,
                                                                limit: Constants::MxCompany::LIMIT_ITEMS)
  end

  def global
    FinkokResponses::GetGlobalFinkokResponse.call(current_community: current_community,
                                                  filter: filter_params,
                                                  page: params[:page],
                                                  options: { instantiate_context: self })
  end

  def notify
    Invoices::NotifyGlobalInvoice.call(@finkok_response, current_community)

    redirect_back(fallback_location: root_path, notice: t('views.finkok_response.notify.notice'))
  end

  private

  def cancel_params
    {
      finkok_response_id: params[:finkok_id],
      cancel_motive: params[:cancel_motive],
      folio: params[:folio]
    }
  end

  def set_finkok_response
    @finkok_reponse = FinkokResponse.find(params[:id])
  end

  def filter
    @finkok_responses = @finkok_responses.where('finkok_responses.irs_at >= ?', params[:filter][:from_date].to_date) if params[:filter][:from_date].present?
    @finkok_responses = @finkok_responses.where('finkok_responses.irs_at <= ?', params[:filter][:to_date].to_date) if params[:filter][:to_date].present?
    if params[:filter][:payment_method].present? && (params[:filter][:payment_method] != 'all')
      @finkok_responses = @finkok_responses.where(payment_method: params[:filter][:payment_method])
    end
    if params[:filter][:property_or_folio].present?
      @finkok_responses = @finkok_responses
                            .left_joins(payment: :property)
                            .where('properties.name ILIKE ? OR payments.folio = ?', "%#{params[:filter][:property_or_folio]}%", params[:filter][:property_or_folio].to_i)
    end
    @finkok_responses
  end

  def filter_params
    return {} unless params[:filter]

    params.require(:filter).permit(:from_date, :to_date, :folio, :property_or_folio)
  end
end
