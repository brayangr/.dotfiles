class CommunitiesController < ApplicationController
  include SettingsHelper
  include OnlinePayments
  require 'will_paginate/array'
  load_and_authorize_resource

  before_action :set_community, only: %i[show edit update avatar signature remuneration_signature company_image change_account property_user_validations_zip activate_new_payments_portal deactivate_new_payments_portal]
  before_action :set_reserve_fund, only: %i[edit update]
  before_action :control_demo_access, only: :update
  before_action :set_logged_in_as_admin
  before_action :redirect_with_admin, only: :index
  before_action -> { redirect_to_residents!(path: Constants::ResidentsPaths::PROPERTIES, force: true) }, only: :index

  include Charts
  # GET /communities
  def index
    session[:logged_as_administrator] = false
    session[:logged_as_property_user] = false

    if only_one_community && !more_than_one_property && current_community.present? && (current_user.is_community_manager? || current_user.is_community_admin? || current_user.is_community_committee?)
      # set one of the communities
      community = Community.joins(:community_users).find_by(community_users: { user_id: current_user.id, active: true })
      session[:community_id] = community&.id
      @current_community = community
      flash.keep
      return redirect_to dashboard_path
    end

    my_community_ids = if params[:as_admin].present?
      current_user.admin_communities.ids
    elsif params[:as_committee].present?
      current_user.committee_communities.ids
    elsif params[:as_manager].present?
      current_user.manager_communities.ids
    else
      current_user.manageable_communities.ids
    end
    @my_communities = Community.where(id: my_community_ids)
    @communities_quantity = @my_communities.size
    if params[:name].present?
      @my_communities = @my_communities.where('lower(name) LIKE ?', "%#{params[:name].downcase}%")
      @name_search = params[:name]
    end
    @my_communities = @my_communities.includes(:period_expenses, :settings).order_by_name(direction: :asc)

    @communities = current_user.communities.includes(:period_expenses)

    @properties = current_user.properties.includes(community: :period_expenses)

    @no_permissions = no_permissions

    if current_user.real_estate_agency.present? && (@my_communities + @communities + @properties).blank?
      flash.keep
      redirect_to real_estate_dashboard_path
    end
  end

  # GET /communities/1
  def show# OPTIMIZE
    # registrar comunidad en sesión
    session[:community_id] = @community.id
    if params[:op] == '1'
      session[:property_id] = nil
    end
    flash.keep

    ## Banner search para propiedades
    if params[:property_id].present? && current_community.properties.ids.include?(params[:property_id].to_i)
      session[:property_id] = params[:property_id].to_i
      return redirect_to property_dashboard_path
    else
      session[:logged_as_administrator] = true
      session[:logged_as_property_user] = false
      return redirect_to ManagerRedirectTree.get_redirect_direction(user: current_user, community: @community) || dashboard_path
    end
  end

  def new
    @source = "new"
    #Si el usuario actual no es el demo, sigue normalmente.
    if current_user.present? and !current_user.demo
      suggested_date = (Date.today.day < 20) ? 1.month.ago : Time.now
      #Si la comunidad actual es la demo (o soy super admin), crea una comunidad nueva.
      if (current_community.present? and current_community.demo) or current_user.admin
        @community = Community.new
        @month = suggested_date.month
        @year = suggested_date.year
      else
        @community = current_community
        expiration_date = @community.last_closed_period_expense.expiration_date
        @month = expiration_date.month
        @year = expiration_date.year
      end
      @community.contact_email = current_user.email if current_user.email.present?

      @regions = Region.all.order('region_order').to_a
      @regions << Region.new(name: 'Sin Especificar', id: 0)
      @communes = Comuna.all.order('name').to_a
      @communes << Comuna.new(name: 'Sin Especificar', id: 0)
    else
      # Cuando el usuario está en la sesión de demo, redirecciona a crear usuario.
      redirect_to new_user_path
    end
  end

  def send_payment_gateways_data_to_new_portal
    messages = []
    alerts = []
    community = Community.find(params['community_id'])
    begin
      client = PaymentPortalApiClient.get_payments_api_client(community)
      if params['is_new']
        parameters = Payments::PaymentsApiClientService.instance.build_request_params_for_create(params, client)
        client.create_payment_gateway_setting(payment_gateway_office_setting: parameters)
      else
        payment_gateway_office_setting_id = params['gateway_setting_id']
        options = Payments::PaymentsApiClientService.instance.build_request_params_for_update(params, client)

        client.update_payment_gateway_setting(payment_gateway_office_setting_id, options)
      end
      messages << t('messages.notices.admin.communities.edit.successfully_updated')
      redirect_to edit_community_path(community, tab: 'payment-gateways'), notice: messages.join('<br>')

    rescue => exception
      alerts << t('messages.errors.admin.communities.edit.error')
      redirect_to edit_community_path(community, tab: 'payment-gateways'), alert: alerts.join('<br>')
    end
  end

  # GET /communities/1/edit
  def edit
    @funds = @community.funds.where(is_reserve_fund: false).includes(:aliquot).paginate(page: params[:page], per_page: 30)
    @fund_types = Fund.RESERVE_FUND_TYPES
    @setting_codes = Setting.code_options(false, false).map { |e| e[0] }
    if current_user.admin?
      @admin_setting_codes = Setting.admin_settings_by_community(@community)
      @module_setting_codes = Setting.module_settings_by_community(@community)
    end

    @happy_suppliers_setting = @community.happy_suppliers_setting
    @uses_period_control = @community.uses_period_control?
    @options_hints = Setting.options_hints

    @tabs = set_setting_tabs
    @tab = params[:tab] || ''

    ###################### NOTE ########################
    # With the implementation of the new portal, the providers must be dynamic
    # according to what the api of the new portal sends and not be wired to
    # some arrays
    if @community.payment_portal_setting.present? && @community.payment_portal_setting.active
      @office_in_new_portal = PaymentPortalApiClient.get_payments_api_client(@community)
      case @community.country_code
      when 'CL'
        if @community.payment_portal_setting.active
          @payment_gateways_availables = PaymentGatewaySetting::NEW_PORTAL_CL_PROVIDERS
        else
          @payment_gateways_availables = PaymentGatewaySetting.webpay_subproducts
        end
      when 'MX'
        # This should go back to PaymentGatewaySetting::MX_PROVIDERS when we get rid of Sr_Pago.
        # Technical Debt -> PaymentGatewaySetting.available_gateways -> Sync.rb
        @payment_gateways_availables = PaymentGatewaySetting::NEW_PORTAL_MX_PROVIDERS
      else
        @payment_gateways_availables = []
      end

      @payment_gateways_items = @office_in_new_portal.payment_gateway_settings['items']
      @payment_gateways_id =  Payments::PaymentsApiClientService.instance.get_payments_gateways_ids_by_office(@office_in_new_portal)
      @payment_gateways_items_id = @payment_gateways_items.map { |each| each['id'] }
      @payments_gateways_configured_in_new_portal = Payments::PaymentsApiClientService.instance.get_mapped_payment_gateways(@payment_gateways_items)
      @new_payment_portal_gateways_settings = Payments::PaymentsApiClientService.instance.create_settings(@payment_gateways_availables, @community, @office_in_new_portal)
      @community_id = @community.id
    end
    ################## END NOTE ########################

    @categories = @community.get_categories.reject(&:public).map { |c| { name: c.to_s, id: c.id, hidden_in_bill: c.hidden_in_bill } }
    @community_remunerations_outcomes_categories = @community.remunerations_outcomes_categories

    @regions = Region.all.order('region_order').to_a
    @regions << Region.first_or_initialize(name: 'Sin Especificar', id: 0)

    @communes = Comuna.all.order('name').to_a
    @communes << Comuna.first_or_initialize(name: 'Sin Especificar', id: 0)

    @source = 'edit'

    @banred_info = @community.banred_info || @community.build_banred_info if @community.uruguayan?
    @mx_company = @community.mx_company || @community.build_mx_company(business_name: @community.name)
    @payment_gateways = @community.payment_gateway_settings

    # Variables de community_transactions
    @min_year = @period_expense&.period&.year
    @bank_reconciliation = current_community.current_bank_reconciliation
    @bank_reconciliation = current_community.get_open_period_expense if @bank_reconciliation.blank?
    @has_closed_reconciliation = current_community.last_closed_not_initial_period_bank_reconciliation.present?
    @community_first_bank_reconciliation = current_community.first_bank_reconciliation
    @bank_accounts = current_community.bank_accounts.by_active.order(created_at: :desc).paginate(page: params[:page], per_page: Constants::BankAccounts::MAX_ITEMS_TO_DISPLAY)
    @new_bank_account = BankAccount.new

    @community.build_visitor_setting unless @community.visitor_setting.present?

    set_banking_settings
    @committee_members = CommitteeMembers::CurrentList.call(current_community).paginate(page: params[:page], per_page: 30)
    @available_owners = CommitteeMembers::AvailableMembers.call(@committee_members, current_community)
    @op_mail_receivers_data = Payments::OnlinePaymentMailReceiversData.call(@community) if @community.online_payment_activated?
    @issues_mail_receivers_data = Issues::IssuesMailReceiversData.call(community: @community).data[:emails]
    @common_space_correspondent_id = common_space_correspondent_data
  end

  def create
    @community = Community.new(community_params)
    # Seteo de datos default importantes para la comunidad.
    @community.comuna = Comuna.find_by(name: params[:communes_select])
    @community.billing_message = I18n.t('views.communities.bills.form.billing_message_content').html_safe
    account = Account.create
    package = Pricing.where(public: true)[0].package
    @community.currency_id = Currency.where(name: "Pesos").first_or_create.id
    @community.account = account
    @community.pricing_package = package
    current_user.current_attributes(community_id: @community&.id, user_id: current_user.id)
    @community.build_banking_setting
    if @community.save
      @community.current_interest
      @community.update_role(current_user, CommunityUser.reversed_roles('Administrador'))
      session[:community_id] = @community.id

      # Obtenemos el mes y año entregados por el usuario y calculamos el anterior para el período.
      user_date = Time.new(params[:year], params[:month])
      period_date = user_date - 1.month
      # Generamos period_expense según el mes y año especificados.
      period_expense = @community.get_period_expense period_date.month, period_date.year
      if !period_expense.initial_setup
        period_expense.initial_setup = true
        period_expense.paid = true
        period_expense.save
        period_expense.pre_close false, true, true, false
        last = period_expense.get_last.first
        last.initial_setup = true
        last.paid = true
        last.save
        last.pre_close false, true, true, false
      end

      redirect_to new_funds_community_path @community
      #redirect_to new_step2_admin_community_path(@community), notice: 'Queda un solo paso para tener la comunidad andando!'
    else
      redirect_to new_community_path, alert: @community.errors.full_messages.join('<br>')
    end
  end

  #Actualiza la lista de comunas según la región seleccionada.
  def update_communes
    region = Region.find_by(id: params[:region_id])
    @communes = region.present? ? region.comunas.order('name') : Comuna.all.order('name')
    @communes << Comuna.first_or_initialize(name: 'Sin Especificar', id: 0)

    render partial: 'commune',
           locals: { communes_options: @communes, current_commune: current_community.present? ? current_community.comuna : 0 }
  end

  def past_administrators
    @past_administrators = @community.past_administrators
  end

  def change_account
    admin_id = @community.administrator.id
    @accounts = Account.joins(communities: :community_users)
                       .where(community_users: {
                                user_id: admin_id,
                                active: true,
                                role_code: CommunityUser.reversed_roles('Administrador')
                              })
    @pricings = @community.pricings
  end

  def download_banred_refresh
    properties = @community.properties.joins(:balance).where('money_balance < 0')

    data = BanredInfos::Converter::PropertiesToBanredData.call(community: @community, properties: properties)
    filename = I18n.t('views.community.download_banred_refresh.filename', date: Date.current.strftime('%Y%m%d'), entity_code: @community.banred_info&.entity_code.to_s)

    send_data(data, filename: filename, type: 'text/plain')
  end

  # PATCH/PUT /communities/1
  def update
    byebug
    @fund_types = Fund.RESERVE_FUND_TYPES
    alerts = []
    messages = []
    tab = params[:tab]
    rut_changed = false
    # Hay un controlador y una vista aparte para actualizar fondos
    # if params[:funds].present? and @community.update_funds(params[:funds])
    #  messages << 'Fondos actualizados'
    # elsif params[:funds].present?
    #  alerts << 'error en actualizar fondos'
    # end
    if params[:tab] == 'bill'
      currently_showing_funds_ids = Fund.where(community: @community, show_service_billings_in_bill: true).pluck(:id)
      form_funds_ids = params[:fund_service_billings].to_a.map(&:to_i)
      funds_to_mark = form_funds_ids - currently_showing_funds_ids
      funds_to_unmark = currently_showing_funds_ids - form_funds_ids
      current_community.funds.where(id: funds_to_mark).update_all(show_service_billings_in_bill: true)
      current_community.funds.where(id: funds_to_unmark).update_all(show_service_billings_in_bill: false)
    end

    if params[:community].present?
      rut_changed = true if community_params[:rut].present? && community_params[:rut] != @community.rut
      if @community.update(community_params)
        messages << t('messages.notices.admin.communities.edit.successfully_updated')
        if rut_changed
          NotifyCommunityRutChange.perform_later(_user: current_user, _community: @community, locale: @community.get_locale)
        end
      else
        alerts << t('messages.errors.admin.communities.edit.error')
        alerts += @community.errors.full_messages
      end
      if params[:community][:pricing_id].present? && @community.get_possibles_pricings.ids.include?(params[:community][:pricing_id].to_i)
        @community.update(pricing_id: params[:community][:pricing_id].to_i)
      end
    end

    if params[:setting].present?
      community_settings = @community.settings
      @access_control = current_community.get_setting 'access_control'
      @access_control_enable_users = current_community.get_setting 'access_control_enable_users'

      online_payment_setting = community_settings.detect { |setting| setting.code == 'online_payment' }
      if params[:setting].keys.include?(online_payment_setting&.id.to_s) && online_payment_setting.value != params[:setting][online_payment_setting&.id.to_s][:value].to_i
        unless can?(:update_online_payment_setting, @community)
          params[:setting] = params[:setting].except(online_payment_setting&.id.to_s)
          alerts << I18n.t('messages.warnings.superadmin_permissions.update_online_payment_setting')
        end
      end

      mes_corrido_setting = community_settings.detect { |setting| setting.code == 'mes_corrido' }
      if params[:setting].keys.include?(mes_corrido_setting&.id.to_s) && mes_corrido_setting.value != params[:setting][mes_corrido_setting&.id.to_s][:value].to_i
        unless can?(:update_mes_corrido_setting, @community)
          params[:setting] = params[:setting].except(mes_corrido_setting&.id.to_s)
          alerts << I18n.t('messages.warnings.superadmin_permissions.update_mes_corrido_setting')
        end
      end

      params[:setting].to_unsafe_h.each do |setting_params|
        setting = community_settings.detect { |set| set.id == setting_params[0]&.to_i }
        if !can?(:update, setting) && setting.value != setting_params[1][:value].to_i
          params[:setting] = params[:setting].except(setting_params[0])
          alerts << I18n.t('messages.warnings.superadmin_permissions.setting.update_setting', setting: setting.name)
        end
      end
    end

    if params[:setting].present? && @community.update_setting(params[:setting], current_user.admin?, current_user)
      if @access_control.value.zero? && params.dig(:setting, @access_control.id.to_s, "value") == "1" && params.dig(:setting, @access_control_enable_users.id.to_s, "value") == "1"
        @current_community.property_users.update_all(access_control_enabled: true)
        success = AccessControl::Communities.synchronize_community(community: current_community)
        raise AccessControl::Error, I18n.t('messages.errors.access_control.unable_to_update') unless success
      end

      messages << 'Configuración actualizada'

      online_payment_setting = @community.get_setting('online_payment')
      @community.update_online_payment_mail_receiver(online_payment_setting.value) if online_payment_setting.previous_changes.key?('value')
      setting_id = @community.get_setting('period_control').id
      @community.discounts.active.update_all(active: false) if params.dig(:setting, setting_id.to_s, 'value') == '1'
      if @community.get_setting('remuneration_service_billing_categories_base').value < 2
        Category.find_category_or_create_v2(Category.community_outcome_category(@community.get_setting('remuneration_service_billing_categories_base').value, @community.id), '', @community)
        Category.where(community_id: @community, community_outcomes_setting: Constants::Categories::CL_BASE_COMMUNITY_REMUNERATIONS_CATEGORIES.index(I18n.t('views.category.new'))).update(community_outcomes_setting: 1)
      end

      update_service_billing_category!
    elsif params[:setting].present?
      alerts << 'error en actualizar la configuración'
    end

    categories = @community.get_categories

    # el parametro hidden categories present está para saber que el usuario viene de la vista correcta
    if categories.any? && params[:hidden_categories_present]
      categories_updated_0 = categories.where(public: false).where(hidden_in_bill: false).where(id: params[:hidden_categories]).update_all(hidden_in_bill: true)
      categories_updated_1 = categories.where(public: false).where(hidden_in_bill: true).where.not(id: params[:hidden_categories]).update_all(hidden_in_bill: false)
      if categories_updated_0 && categories_updated_1
        if categories_updated_0 + categories_updated_1 > 0
          messages << 'Categorías ocultas actualizadas'
        end
      else
        alerts << 'error en actualizar las categorías ocultas'
      end
    end
    if alerts.empty?
      if community_params[:account_id].present?
        return redirect_to accounts_path(community_id: @community.id), notice: messages.join('<br>')
      end

      if params[:modify_salary_payments]
        UpdateAdvanceServiceBillingCategoryJob.perform_later(community_id: @community.id, _message: "Actualizando categoría de avances de período en curso - #{@community.to_s}")
        UpdateSalaryPaymentServiceBillingCategoryJob.perform_later(community_id: @community.id, _message: "Actualizando categoría de liquidaciones de período en curso - #{@community.to_s}")
        UpdateFiniquitoServiceBillingCategoryJob.perform_later(community_id: @community.id, _message: "Actualizando categoría de finiquitos de período en curso - #{@community.to_s}")

        if community_params[:mutual].present?
          period_expense_id = current_community.get_open_period_expense
          SalaryPayment.left_joins(:employee)
            .select("salary_payments.id, INITCAP(TRIM(CONCAT(employees.first_name, ' ', employees.father_last_name, ' ', employees.mother_last_name))) as employee_name")
            .where(payment_period_expense_id: period_expense_id, nullified: false)
            .each do |salary_payment|
              CalculateSalaryJob.perform_later(_community_id: @community.id, salary_payment_id: salary_payment.id, _message: "Recalculando #{I18n.t('activerecord.models.salary_payment.one').downcase} de sueldo de #{salary_payment.employee_name} - #{@community.to_s}")
            end
        end
      end

      case params[:source]
      when 'new'
        return redirect_to new_funds_community_path(@community, tab: tab)
      else
        return redirect_to edit_community_path(@community, tab: tab), notice: messages.join('<br>')
      end
    else
      if params[:source] == 'new'
        return redirect_to new_community_path(tab: tab), notice: 'Error en la edición de comunidad'
      else
        return redirect_to edit_community_path(@community, tab: tab), alert: alerts.join('<br>')
      end
    end

  rescue AccessControl::Error => e
    redirect_back fallback_location: edit_community_path(current_community.id), alert: e.message
  end


  def update_data_after_preview
    eu = JSON.parse params[:excel_upload]

    DataImportJob.perform_later(_community_id: eu.community_id, excel_upload_id: eu.id, _message: 'Importando información desde excel al sistema')

    redirect_to import_data_path(eu.name), notice: 'Procesando Excel'
  end

  def create_massive_relations
    Matchfeliz::MassiveUniqueRelations.new(current_user: current_user, current_community: current_community).bulk_create

    redirect_to ThirdParty::TokenManager.new(current_user: current_user, current_community: current_community).build_match_feliz_link(flash_message: I18n.t('notice.community.massive_creation_start'))
  end

  ##########################
  ######    Fondos    ######
  ##########################
  def new_funds
    @community = current_community
    @reserve_fund = @community.reserve_fund.present? ? @community.reserve_fund : Fund.new( name: "Fondo de reserva", is_reserve_fund: true, fund_type: Fund.get_type("Porcentual"))
    @fund_types = Fund.RESERVE_FUND_TYPES
  end

  def create_funds
    @fund = @community.save_reserve_fund_by(reserve_fund_params)
    if @fund.valid?
      @community.update(installation_step: 3)
      redirect_to new_contacts_community_path(@community), notice: "Fondo de reserva creado"
    else
      redirect_to new_funds_community_path(@community), alert: "<b>No se pudo crear fondo de reserva</b> <br> #{@fund.errors.full_messages.join("<br>")}"
    end
  end

  def update_reserve_fund
    messages = ""
    alerts = ""
    params[:reserve_fund_fixed] = 0 if params[:fund_type] == "2"
    if params[:setting].present? && @community.update_setting(params[:setting], current_user.admin?, current_user)
      messages << "Configuración actualizada"
    elsif params[:setting].present?
      alerts << "error en actualizar la configuración"
    end
    # Prepare show_service_billings_in_bill (sends "on" or doesn't send anything!)
    additional_reserve_fund_params = reserve_fund_params
    additional_reserve_fund_params[:show_service_billings_in_bill] = params[:show_service_billings_in_bill].present?
    @fund = @community.save_reserve_fund_by(additional_reserve_fund_params)
    if @fund.valid?
      messages << "\<br\>Fondo de reserva actualizado"
    else
      alerts << "\<br\>No se pudo crear fondo de reserva\</b\> \<br\> #{@fund.errors.full_messages.join("\<br\>")}"
    end
    if alerts.empty?
      redirect_to edit_community_path(current_community.id, tab: "funds"), notice: messages
    else
      redirect_to edit_community_path(current_community.id, tab: "funds"), alert: alerts
    end
  end
  #########################
  ######  Contactos  ######
  #########################
  def new_contacts
    @community = current_community
  end

  def create_contacts
    if params[:contacts_attributes].blank?
      @community.update(installation_step: 4)
      return redirect_to new_properties_select_community_path(@community)
    end

    if @community.update(community_params)
      @community.update(installation_step: 4)
      redirect_to new_properties_select_community_path(@community), notice: "Contactos creados"
    else
      redirect_to new_contacts_community_path(@community), alert: "No se pudieron crear los contactos."
    end
  end

  #########################
  ###### Propiedades ######
  #########################
  def new_properties_select
    @community = current_community

    return redirect_to dashboard_path, notice: t('messages.notices.communities.properties_already_entered') if @community.properties.count > 0
  end

  def new_properties_excel
    @community = current_community
    @proration = @community.get_setting_value("proration")
    @excel_upload = ExcelUpload.new(community_id: @community.id)

    return redirect_to dashboard_path, notice: t('messages.notices.communities.properties_already_entered') if @community.properties.count > 0
  end

  def new_properties_from_excel
    @community = current_community
    @proration = @community.get_setting_value("proration")
    @info = params[:info]

    return redirect_to dashboard_path, notice: t('messages.notices.communities.properties_already_entered') if @community.properties.count > 0

    render :new_properties
  end

  def create_properties
    #Separamos la funcionalidad según el botón presionado (subir excel o continuar con la creación)
    if params[:commit] == 'Subir'
      eu = ExcelUpload.new(excel_upload_params)
      eu.uploaded_by = current_user.id
      eu.community_id = current_community.id
      eu.admin = current_user.admin?
      eu.save

      @info = Community.excel_preimport_properties eu

      return redirect_to new_properties_from_excel_community_path(community: @community, info: @info), notice: "Excel cargado"
    else
      #Revisamos que no haya propiedades con el mismo nombre.
      grouped_by_names = params[:community][:properties_attributes].values.select{ |r| r[:_destroy] != "1" }.group_by{ |p| p[:name] }
      #Revisamos que cada conjunto de tuplas de la misma propiedad tenga el mismo prorrateo y el mismo saldo.
      grouped_by_names.each do |_,property_params|
        if property_params.map{ |p| p[:size] }.uniq.count > 1 || property_params.map{ |p| p[:price] }.uniq.count > 1
          @community = current_community
          return redirect_to new_properties_excel_community_path(@community), alert: t('messages.errors.communities.same_name_bad_info')
        end
      end

      @info = []
      unique_params_array = community_params.to_h["properties_attributes"].values.uniq { |p| p["name"] }
      unique_params = ActionController::Parameters.new
      unique_params["properties_attributes"] = {}
      unique_params_array.each_with_index do |params, index|
        unique_params["properties_attributes"]["#{index}"] = params
      end

      if @community.update(unique_params.permit({:properties_attributes => [:id, :name, :size, :excel_upload_id, :_destroy]}))
        #Si el usuario aceptó, se utiliza la setting normalizada (0). Si no, no.
        proration_setting = {}
        setting = @community.get_setting "proration"
        proration_setting[setting.id] = {}
        proration_setting[setting.id]["value"] = (params[:proration_answer] == "true") ? 0 : 1
        #Actualizamos la setting.
        @community.update_setting proration_setting, current_user.admin?, current_user

        #Creamos un job para hacer la creación masiva.
        SetupCreatedPropertiesJob.perform_later(community_id: @community.id, params: params, current_user_id: current_user.id, _message: t('controllers.communities.importing_properties', community_id: @community.id, community: @community.to_s ))
        @community.update(installation_step: 5)

        if false #current_user.admin?
          redirect_to admin_community_path(@community), notice: 'Procesando Excel...'
        else
          redirect_to @community, notice: t('messages.notices.communities.creating_properties')
        end
      else
        return redirect_back(fallback_location: root_path, alert: t('messages.errors.communities.properties_could_not_be_created'))
      end
    end
  end

  def data_sample_properties_excel
    #TODO: Falta buscar una forma de obtener las rows creadas en el form para precargarlas en el excel.
    #UPDATE: Actualmente, como están separados los caminos, no es necesario esto porque los caminos no son paralelizables.
    old_rows = []

    @file_excel = Community.generate_excel_import_properties old_rows
    respond_to do |format|
      format.xls do
        filename = t('controllers.communities.import_filename')
        send_data @file_excel.string, disposition: 'attachment', filename: filename
      end
    end
  end

  def import_properties_from_excel
    excel_upload = ExcelUpload.new(excel_upload_params)

    #Límite de tamaño de Excel.
    max_file_size = 125000
    return redirect_back(fallback_location: root_path, alert: "El archivo es demasiado grande, por favor contáctanos") if excel_upload.excel.size > max_file_size

    #Límite de Excels subidos.
    max_number_of_files = 10
    return redirect_to dashboard_path, alert: "Has subido demasiados archivos, por favor contáctanos" if ExcelUpload.where(name: t('controllers.communities.initial_properties'), uploaded_by: current_user.id).count > max_number_of_files unless current_user.admin?

    excel_upload.uploaded_by = current_user.id
    excel_upload.admin = current_user.admin?
    excel_upload.name = t('controllers.communities.initial_properties')
    excel_upload.community_id = current_community.id
    excel_upload.save

    @community = current_community
    @proration = @community.get_setting_value("proration")

    return redirect_to dashboard_path, notice: t('messages.notices.communities.properties_already_entered') if @community.properties.count > 0

    #Revisamos la cantidad de propiedades que se intentarán cargar.
    excel_length = Community.get_properties_excel_length excel_upload

    if excel_length < 20 ###  CAMBIAR ESTO!  ### !!!
      #Si son pocas, se cargan directamente en la vista.
      @info = Community.excel_preimport_properties excel_upload

      @properties = []
      @info.each do |row|
        if row['departamento'].present?
          property = Property.new(name: row['departamento'], size: row['prorrateo'], excel_upload_id: excel_upload.id)
          @properties << property
        end
      end

      render :preload_properties_from_excel
    else
      #Si son muchas, se carga el preview para luego cargar directamente en la DB.
      @info_preview = Community.excel_preimport_N_properties excel_upload, 20
      @excel_upload_id = excel_upload.id

      render :import_properties_from_excel
    end
  end

  def load_properties_directly_from_excel
    excel_upload = ExcelUpload.find(params[:excel_upload_id].to_i) unless params[:excel_upload_id].blank?
    @community = current_community
    @proration = @community.get_setting_value("proration")

    return redirect_to dashboard_path, notice: t('messages.notices.communities.properties_already_entered') if @community.properties.count > 0

    #Creamos e inicializamos las propiedades a partir del excel.
    ExcelDirectImportPropertiesJob.perform_later(community_id: @community.id, excel_upload_id: excel_upload.id, current_user_id: current_user.id, _message: t('controllers.communities.importing_properties', community_id: @community.id, community: @community.to_s))

    @community.update(installation_step: 5)

    if current_user.admin?
      redirect_to admin_community_path(@community), notice: 'Procesando Excel...'
    else
      redirect_to @community, notice: "Procesando Excel..."
    end
  end

  def maintenance_mode
    @transparent_container = true
  end

  def avatar
    redirect_to @community.avatar.expiring_url(10)
  end

  def signature
    redirect_to @community.signature.expiring_url(10)
  end

  def remuneration_signature
    redirect_to @community.remuneration_signature.expiring_url(10)
  end

  def company_image
    redirect_to @community.company_image.expiring_url(10)
  end

  def delete_attach
    case params[:name]
    when 'signature'
      current_community.remove_signature!
      current_community.save
      flash[:warning] = I18n.t('notice.community.delete_signature')
      redirect_to edit_community_path(current_community)
    when 'company_image'
      current_community.remove_company_image!
      current_community.save
      flash[:warning] = I18n.t('notice.community.delete_logo')
      redirect_to edit_community_path(current_community)
    when 'remuneration_signature'
      current_community.remove_remuneration_signature!
      current_community.save
      flash[:warning] = I18n.t('notice.community.delete_remuneration_signature')
      redirect_to edit_community_path(current_community, tab: params[:tab])
    else
      flash[:danger] = I18n.t('notice.community.file_not_found')
      redirect_to edit_community_path(current_community)
    end
  end

  def period_expenses_registry
    @month = params[:month]
    @year = params[:year]
    @period_expense_registers = PeriodExpenseRegister.joins(:period_expense).includes(:responsible).where(period_expenses: { community_id: current_community.id })
    @period_expense_registers = @period_expense_registers.where('extract (year from period_expenses.period) = ?', @year) unless @year.blank?
    @period_expense_registers = @period_expense_registers.where('extract (month from period_expenses.period) = ?', @month) unless @month.blank?
    @period_expense_registers = @period_expense_registers.order(date: :desc).paginate(page: params[:page], per_page: PeriodExpenseRegister::PAGE_SIZE)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def collection_excel
    return redirect_to bills_path, alert: I18n.t('excels.billing_sheet.error.cannot_generate') if current_community.last_closed_period_expense.initial_setup

    helpers.mp_tracking(event_name: 'Bill', additional_info: { action: I18n.t('mixpanel.bill.collection_excel') })
    period_expense = current_community.last_closed_period_expense
    respond_to do |format|
      format.xlsx do
        if period_expense.common_expenses.count > 180
          # Create job to send it through email
          SendCollectionExcelJob.perform_later(_community_id: current_community.id, user_id: current_user.id, _message: I18n.t('excels.billing_sheet.notify.sending'))
          redirect_to bills_path, notice: I18n.t('excels.billing_sheet.notify.send')
        else
          file_excel = current_community.generate_collection_excel
          send_data file_excel.to_stream.read, filename: I18n.t('excels.billing_sheet.file_name', period_expense: period_expense, current_community: current_community), type: 'application/vnd.openxmlformates-officedocument.spreadsheetml.sheet'
        end
      end
    end
  end

  def property_user_validations_zip
    GeneratePropertyUserValidationsZipJob.perform_later(_community_id: current_community.id, admin_id: current_user.id)

    redirect_to property_users_path, notice: I18n.t('views.notify_admin_property_user_validations_zip')
  end

  def activate_new_payments_portal
    return redirect_to edit_community_path(@community, tab: 'payment-gateways'), alert: I18n.t('views.payment_portal_setting.warning.activation_error') unless @community

    creator = OnlinePayments::Offices::Creator.new(community: @community)

    if creator.call
      flash[:notice] = I18n.t('views.payment_portal_setting.notice.activated')
    else
      flash[:warning] = I18n.t('views.payment_portal_setting.warning.activation_error', error: creator.response)
    end

    redirect_to edit_community_path(@community, tab: 'payment-gateways')
  end

  def deactivate_new_payments_portal
    return redirect_to edit_community_path(@community, tab: 'payment-gateways'), alert: I18n.t('views.payment_portal_setting.warning.deactivation_error') unless @community

    if @community.payment_portal_setting.inactive!
      flash[:notice] = I18n.t('views.payment_portal_setting.notice.deactivated')
    else
      flash[:warning] = I18n.t('views.payment_portal_setting.warning.deactivation_error')
    end

    redirect_to edit_community_path(@community, tab: 'payment-gateways')
  end

  private

  def set_banking_settings
    return if @community.country_code != 'MX'

    @banking_setting = BankingSetting.where(community_id: current_community.id).first_or_initialize
    @internal_banking_setting = InternalBankingSetting.where(community_id: current_community.id).first_or_initialize
    set_costs_center

    @banking_setting.save if @banking_setting.valid?

    return unless @tab == 'banking_settings' && session[:banking_setting].present?

    @banking_setting = @banking_setting.valid? ? @banking_setting : session[:banking_setting]
    session.delete(:banking_setting)
  end

  def set_costs_center
    return unless @banking_setting.new_record? && BankingSetting.exists?(costs_center: @banking_setting.costs_center,
                                                                         stp_account_number: @banking_setting.stp_account_number)

    @banking_setting.costs_center = BankingSetting.next_costs_center
    @banking_setting.save!
  end

  def committee_member_params
    params.require(:community).require(:committee_members_attributes)
  end

  # Only allow a trusted parameter 'white list' through.
  def excel_upload_params
    params.require(:excel_upload).permit(:excel, :name)
  end

  def control_demo_access
    return unless !current_user.admin? && (current_user.demo || current_community.demo)

    redirect_to property_users_path, alert: 'No se puede cambiar mientras estás en demo'
  end

  def redirect_with_admin
    redirect_to admin_home_path if current_user.admin
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_community
    return unless current_user.admin? || current_user.all_communities_ids.include?(params[:id])

    @community = Community.includes(:settings).find(params[:id])
  end

  def set_reserve_fund
    @reserve_fund = @community.reserve_fund.present? ? @community.reserve_fund : Fund.where(is_reserve_fund: true, fund_type: Fund.get_type("Porcentual"), community_id: @community.id).first_or_create(name: "Fondo de reserva", price: 0.0)
  end

  def reserve_fund_params
    params.permit(:percentage, :initial_price, :fund_type, :reserve_fund_fixed, :show_service_billings_in_bill)
  end

  # Only allow a trusted parameter 'white list' through.
  def community_params
    return ActionController::Parameters.new unless params[:community].present?

    result = [
      :account_id, :address, :amount_to_notify_slow_payers, :avatar, :bank, :bcc_email, :bill_decimals, :bill_header_1,
      :bill_header_2, :billing_message, :ccaf, :charge_notification_message, :city, :common_price, :company_image, :comuna_id,
      :contact_email, :contact_name, :contact_phone, :common_space_correspondent_id, :currency_code, :day_of_month_to_notify_defaulty,
      :days_post_due_date, :days_pre_due_date, :defaulting_days, :description, :email_text_post_due_date, :email_text_pre_due_date,
      :expiration_day, :interest_fund_id, :isl_value, :issues_mail_receiver_id, :last_message, :mail_text, :mail_text_payment,
      :morosity_min_amount, :morosity_months, :morosity_text, :morosity_title, :mutual, :mutual_value, :name, :notification_email_footer,
      :op_mail_receiver_id, :phone, :region_id, :remuneration_signature, :reserve_fund, :reserve_fund_fixed, :reserve_fund_initial_balance,
      :rfc, :signature, :sucursal_pago_mutual, :total_m2, :timezone, :workers_union_rut
    ]

    # Alícuotas
    result << { aliquots_attributes: %i[_destroy id name proration_type] }

    # Contactos
    result << { contacts_attributes: %i[_destroy id name phone position] }

    # Fondos
    result << { funds_attributes: %i[active _destroy fund_type id initial_price name price] }

    # Mx Company
    result << { mx_company_attributes: %i[id postal_code] }

    ## Address
    result << { administrative_address_attributes: %i[id administrative_area_level_1 locality] }

    # Permitir folio
    if current_user.admin? || current_community.get_setting_value('folio') > 0
      result += [bill_folio_attributes:  %i[folio folio_type],
                 income_folio_attributes: %i[folio folio_type],
                 payment_folio_attributes:  %i[folio folio_type],
                 service_billing_folio_attributes: %i[folio folio_type],]
    end

    # Interés
    result << { community_interests_attributes: [
      :amount,
      :compound,
      :currency_id,
      :fixed_daily_interest,
      :minimun_debt,
      :only_common_expenses,
      :price,
      :price_type,
      :rate_type
    ] }

    # Propiedades
    result << { properties_attributes: %i[_destroy excel_upload_id id name size] }

    if current_user.admin?
      result << { webpay_setting_attributes: [
        :commerce_code,
        :commerce_code_oneclick,
        :credit_commission,
        :credit_commission_oneclick,
        :debit_commission,
        :debit_commission_oneclick,
        :delta,
        :delta_oneclick,
        :id,
        :phi,
        :phi_oneclick,
        :country_code
      ] }
      result += %i[accessible bcc_email count_csm country_code lost rut]
    end

    result << {
      online_payment_requests_attributes: [
        :account_document,
        :account_email,
        :account_number,
        :bank,
        :requester_document,
        :signer_name,
        account_identity_attributes: %i[identity identity_type],
        account_document_attributes: %i[document],
        requester_document_attributes: %i[document]
      ]
    }

    result << { visitor_setting_attributes: %i[id flexibility_in_minutes strict_community] }

    result << { property_account_statement_setting_attributes: %i[day_of_month id] }

    result << { happy_suppliers_setting_attributes: %i[id active url] }

    result << { free_debt_certificate_setting_attributes: %i[message] }

    # Check first the existence of the user for the committee members.
    # If a person creates a committee member with an owner that has just been deleted
    # the committee member will be created related to a different owner.
    # To prevent this to happen here the committee_members params related to a
    # deleted user are trimmed here.
    processed_comm_params = params.require(:community).permit(result)
    if processed_comm_params.key?(:online_payment_requests_attributes)
      processed_comm_params[:online_payment_requests_attributes]['0'][:uploader_id] = current_user.id
    end
    processed_comm_params
  end

  def common_space_correspondent_data
    query = CommonSpaceCorrespondentQueries.common_space_correspondent_candidates(community_id: @community.id)
    result = ActiveRecord::Base.connection.exec_query(query)

    formatted_data = result.map do |record|
      ["#{record['first_name']} #{record['last_name']}: #{record['user_email']}", record['user_id']]
    end
    formatted_data.unshift([I18n.t('models.community.common_space_correspondent_data', email: @community.contact_email), -1])
  end

  def update_service_billing_category!
    service_billing_category_param = params['service-billing-categories-selection']
    category_index = Constants::Categories::CL_BASE_COMMUNITY_REMUNERATIONS_CATEGORIES.index(I18n.t('views.category.new'))

    return unless service_billing_category_param.present? && @community.get_setting('remuneration_service_billing_categories_base').value == category_index

    @community.categories.where(id: service_billing_category_param).update(community_outcomes_setting: category_index)
  end
end
