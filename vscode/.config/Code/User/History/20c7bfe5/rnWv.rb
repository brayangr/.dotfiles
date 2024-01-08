module MxCompaniesHelper
  def parse_date(params, key)
    params[:filter]&.dig(key)&.present? ? params[:filter][key].to_datetime.strftime('%d/%m/%Y') : nil
  end

  def parse_value(params, key)
    params[:filter]&.dig(key)&.present? ? params[:filter][key] : 'all'
  end

  def irs_payment_error(payment)
    finkok_response = payment&.finkok_response || payment&.grouped_finkok_response
    response = finkok_response&.irs_payment_error
    response.present? ? response : I18n.t('views.mx_companies.irs.tooltip.default')
  end

  def class_irs_payment_status(payment)
    case payment.irs_status
    when 1
      'irs processing'
    when 2
      'irs failed'
    when 3
      'irs successfull'
    when 4
      'irs billing'
    else
      'irs'
    end
  end

  def complement_payment_error(payment)
    "Error #{payment&.finkok_complement&.error_code}: #{payment&.finkok_complement&.error_description}."
  end

  def complement_cancel_error(complement)
    "#{complement.human_complement_status}: #{complement.estatus_uuid} - #{complement.estatus_cancelacion}"
  end

  def irs_tabs_hash(active: nil)
    %i[pending billed global canceled].map do |tab|
      hash = send("#{tab}_irs_tab_hash")

      active.present? && active == tab ? hash.merge(options: { class: 'active' }) : hash
    end
  end

  def pending_irs_tab_hash
    { text: I18n.t('mx_companies.irs.pending_bills'), link: irs_mx_companies_path }
  end

  def billed_irs_tab_hash
    { text: t('mx_companies.irs.billed_payments'), link: irs_billed_mx_companies_path }
  end

  def canceled_irs_tab_hash
    { text: I18n.t('mx_companies.irs.canceled_bills'), link: cancelled_finkok_responses_path }
  end

  def global_irs_tab_hash
    { text: I18n.t('mx_companies.irs.global_irs'), link: global_finkok_responses_path }
  end

  def data_for_billing_logic(payment)
    property = payment.property

    if property.present?
      user = property&.in_charge&.first
      profile = @profiles[user&.id]
      identification = profile.present? ? profile&.identification&.identity : user&.identifications&.first&.identity.to_s

      return { in_charge: user,
               missing_configurations: get_missing_configurations(property, user: user, profile: profile, profile_cached: true),
               can_global_invoice: payment.payment_type != 'pending',
               identification: identification }
    end

    { in_charge: nil,
      missing_configurations: true,
      can_global_invoice: false }
  end

  def fiscal_name(user)
    person = user.community_profile(community_id: current_community.id, cached: user.profiles_loaded?) || user
    person.fiscal_identification&.name.present? ? person.fiscal_identification.name : person.full_name_unformatted&.upcase
  end

  def irs_date_filter_params(filter_params)
    return filter_params if filter_params[:to_date].present?

    if filter_params[:from_date].present?
      filter_params[:to_date] = Date.today
      return filter_params
    end

    filter_params[:from_date] = Date.today - 30.days
    filter_params[:to_date] = Date.today
    filter_params
  end
end
