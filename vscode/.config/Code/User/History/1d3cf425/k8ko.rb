class MxCompaniesController < ApplicationController
  load_and_authorize_resource

  before_action :validate_irs_package, except: %i[create update]
  before_action :set_mx_company, only: [ :update, :csd_key, :csd_cer, :irs_all ]
  before_action :irs_validations, only: [:irs_all, :create_complement]
  # POST /mx_companies
  # POST /mx_companies.json
  def create
    @mx_company = MxCompany.new(mx_company_params)
    @mx_company.community_id = current_community.id
    respond_to do |format|
      if @mx_company.save
        MxCompanies::NotifyIrsDocumentation.call(mx_company: @mx_company, user: current_user) unless current_user.admin?
        return active_irs_package unless @mx_company&.missing_configurations

        format.html { redirect_to edit_community_path(current_community, tab: 'irs-mx'), notice: I18n.t('messages.notices.mx_companies.create') }
      else
        format.html { redirect_to edit_community_path(current_community, tab: 'irs-mx'), alert: "#{t(:errors_prevented, scope: %i[messages errors commons], count: @mx_company.errors.count)}: #{@mx_company.errors.full_messages.join(',')}" }
      end
    end
  end

  # PATCH/PUT /mx_companies/1
  # PATCH/PUT /mx_companies/1.json
  def update
    respond_to do |format|
      @mx_company.assign_attributes(mx_company_params)
      changed = @mx_company.changed?

      if @mx_company.save
        MxCompanies::NotifyIrsDocumentation.call(mx_company: @mx_company, user: current_user) unless current_user.admin? || !changed
        return active_irs_package unless @mx_company.missing_configurations

        format.html { redirect_to edit_community_path(current_community, tab: 'irs-mx'), notice: I18n.t('messages.notices.mx_companies.update') }
      else
        format.html { redirect_to edit_community_path(current_community, tab: 'irs-mx'), alert: "#{t(:errors_prevented, scope: %i[messages errors commons], count: @mx_company.errors.count)}: #{@mx_company.errors.full_messages.join(',')}" }
      end
    end
  end

  def irs_all
    notify = payment_params[:notify] == 'true'
    MxCompanies::IrsAllResponse.call(**{ community: current_community, filter_params: JSON.parse(params[:filter_params]).symbolize_keys, payment_params: payment_params }, options: { instantiate_context: self })

    notice = notify ? t('views.mx_companies.email_billed_payments.payments_being_billed_and_notified') : t('views.mx_companies.email_billed_payments.payments_being_billed')
    redirect_to irs_mx_companies_path, notice: notice
  end

  def irs_global
    notify = payment_params[:notify] == 'true'
    run_payment_irs_global_job(payments_to_bill, notify)

    notice = notify ? t('views.mx_companies.email_billed_payments.payments_being_billed_and_notified') : t('views.mx_companies.email_billed_payments.payments_being_billed')
    redirect_to(irs_mx_companies_path, notice: notice)
  end

  def irs
    redirect_if_not_invoice_ready_country

    respond_to do |format|
      format.html do
        MxCompanies::IrsResponse.call(community: current_community, filter_params: filter_params, page: params[:page], options: { instantiate_context: self })
      end
    end
  end

  def validate_irs_package
    redirect_to upselling_irs_promotion_path unless !mx_company&.missing_configurations && community_has_active_package?('FC_4')
  end

  def active_irs_package
    return redirect_to irs_mx_companies_path if community_has_active_package?('FC_4')

    base_package = BasePackage.where(package_type: 'FC_4').order('base_price DESC').first
    create_irs_community_package(base_package)
    redirect_to irs_mx_companies_path
  end

  def create_irs_community_package(base_package)
    CommunityPackage.create(
      {
        name: base_package.name,
        country_code: base_package.country_code,
        package_type: base_package.package_type,
        currency_type: base_package.currency_type,
        invoice_type: base_package.invoice_type,
        months_to_bill: 1,
        next_billing_date: next_billing_date,
        periodicity: '1.month',
        exempt_percentage: 0,
        community_id: current_community.id,
        account_id: current_community.account.id,
        price: base_package.base_price,
        upselling: true
      }
    )
  end

  def next_billing_date
    today = Date.today
    next_current_month_billing_date = Date.new(today.year, today.month, 14)
    today < Date.new(today.year, today.month, 10) ? next_current_month_billing_date : next_current_month_billing_date.next_month
  end

  def mx_company
    @mx_company ||= current_community&.mx_company
  end

  def irs_billed
    redirect_if_not_invoice_ready_country

    respond_to do |format|
      format.html do
        MxCompanies::IrsBilledResponse.call(**irs_billed_params.merge(pagination_params), options: { instantiate_context: self })
      end
    end
  end

  def email_billed_payments
    @payments = billed_payments.includes(:finkok_response).where(finkok_response: { cancelled: false })
    @payments = filter_payments if params[:filter].present?
    payments_count = @payments.count

    if payments_count.zero?
      redirect_to irs_billed_mx_companies_path, alert: I18n.t('views.mx_companies.email_billed_payments.no_payments_alert')
    elsif payments_count >= MxCompany::MAX_BILLED_PAYMENTS_TO_EMAIL
      redirect_to irs_billed_mx_companies_path, alert: I18n.t('views.mx_companies.email_billed_payments.max_payments_alert')
    else
      SendBilledPaymentsJob.perform_later(community_id: current_community.id,
                                          current_user_id: current_user.id,
                                          files_format: params[:files_format],
                                          date_range: filter_params.to_h,
                                          _message: I18n.t('jobs.send_billed_payments'))

      redirect_to irs_billed_mx_companies_path, notice: I18n.t('views.mx_companies.email_billed_payments.notice', email_to: current_user.email)
    end
  end

  def email_billed_payments_report
    @payments = billed_payments
    @payments = filter_payments if params[:filter].present?
    payments_count = @payments.count

    if payments_count.zero?
      redirect_to irs_billed_mx_companies_path, alert: I18n.t('views.mx_companies.email_billed_payments.no_payments_alert')
    elsif payments_count >= MxCompany::MAX_BILLED_PAYMENTS_TO_EMAIL
      redirect_to irs_billed_mx_companies_path, alert: I18n.t('views.mx_companies.email_billed_payments.max_payments_alert')
    else
      SendBilledPaymentsReportJob.perform_later(community_id: current_community.id,
                                                current_user_id: current_user.id,
                                                date_range: filter_params.to_h,
                                                _message: I18n.t('jobs.send_billed_payments_report'))

      redirect_to irs_billed_mx_companies_path, notice: I18n.t('views.mx_companies.email_billed_payments.report_notice', email_to: current_user.email)
    end
  end

  def csd_key
    redirect_to @mx_company.csd_key.expiring_url(10)
  end

  def csd_cer
    redirect_to @mx_company.csd_cer.expiring_url(10)
  end

  def create_complement
    payments = current_community.payments.where(id: payment_params[:ids]).not_pending if payment_params.present?

    if payments.present?
      FinkokResponse.payments(payments).update_all(complement_status: :complement_in_queue)
      run_payment_irs_complement_all_job(payments)
    end
    redirect_to irs_billed_mx_companies_path
  end

  def set_user_identification_data
    id = JSON.parse(params[:user_id])
    data = MxCompanies::UserIdentificationData.call(user_id: id, community_id: current_community.id).data[:fiscal_identification]

    render json: data, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mx_company
    @mx_company = current_community.mx_company
  end

  def invoice_recipient_params
    params.require(:invoice_recipient).permit(:business_name, :cfdi_use, :fiscal_regime, :postal_code, :rfc, :user_id)
  end

  def irs_billed_params
    {
      community_id: current_community.id,
      filters: filter_params
    }
  end

  def pagination_params
    {
      page: params[:page],
      per_page: params[:per_page]
    }
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def mx_company_params
    params.require(:mx_company).permit(:postal_code, :business_name, :fiscal_regime, :periodicity, :rfc, :constancia_situacion_fiscal, :csd_key, :csd_cer, :csd_password)
  end

  def payment_params
    params.require(:payments).permit(:notify, ids: [], general_public_ids: [])
  end

  def periodicity_params
    params.require(:periodicity).permit(:month, :type)
  end

  def filter_params
    return {} unless params[:filter]

    params.require(:filter).permit(:from_date, :to_date, :payment_type, :payment_method, :property_or_folio)
  end

  def filter_payments
    @payments = @payments.where('payments.paid_at >= ?', filter_params[:from_date].to_date) if filter_params[:from_date].present?
    @payments = @payments.where('payments.paid_at <= ?', filter_params[:to_date].to_date) if filter_params[:to_date].present?
    @payments = @payments.where(payment_type: filter_params[:payment_type]) if filter_params[:payment_type].present? && filter_params[:payment_type] != 'all'
    @payments = @payments.where(finkok_responses: { payment_method: filter_params[:payment_method] }) if filter_params[:payment_method].present? && filter_params[:payment_method] != 'all'

    if filter_params[:property_or_folio].present?
      @payments = @payments
        .joins(:property)
        .where('properties.name ILIKE ? OR payments.folio = ?', "%#{filter_params[:property_or_folio]}%", filter_params[:property_or_folio].to_i)
    end
    @payments
  end

  def irs_validations
    return redirect_to irs_mx_companies_path, alert: t('controllers.mx_companies.irs_all.alert') unless current_community.mx_company.present?
    return redirect_to irs_mx_companies_path, alert: current_community.mx_company.missing_configurations.to_sentence if current_community.mx_company.missing_configurations.present?
  end

  def billed_payments
    @billed_payments ||= current_community.all_payments.not_adjustment
  end

  def payments_to_bill
    @payments_to_bill ||=
      if payment_params[:ids].present?
        current_community.all_payments.irs_pending.where(id: payment_params[:ids])
      else
        @mx_company.pending_irs
      end
  end

  def redirect_if_not_invoice_ready_country
    redirect_to current_community.uses_period_control? ? bills_path : no_period_bills_path unless is_invoice_ready?(current_community.country_code)
  end

  def run_payment_irs_complement_all_job(payments)
    return unless payments.present?

    PaymentIrsComplementAllJob.perform_later(
      _community_id: current_community.id,
      _message:      t('jobs.payment_irs_complement_all', folios: payments.map(&:folio).join(', ')),
      payments_ids:  payments.ids,
      general_public_ids: payment_params[:general_public_ids] || []
    )
  end

  def run_payment_irs_global_job(payments, notify)
    return unless payments.present?

    PaymentIrsGlobalJob.perform_later(
      _community_id: current_community.id,
      _message: t('jobs.payment_irs_all', folios: payments.map(&:folio).join(', ')),
      invoice_recipient_params: invoice_recipient_params,
      payments_ids: payments.ids,
      periodicity: periodicity_params,
      notify: notify
    )
  end
end
