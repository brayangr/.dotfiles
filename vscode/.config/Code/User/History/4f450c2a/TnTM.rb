class Abilities::AdminManager
  include CanCan::Ability

  def initialize(user, current_community, admin_communities_ids, attendant_communities_ids, properties_ids, repair, committee_communities_ids)
    @user                     = user
    @current_community        = current_community
    @admin_communities_ids    = admin_communities_ids
    @communities_ids          = (admin_communities_ids + attendant_communities_ids + committee_communities_ids)
    @properties_ids           = properties_ids
    @is_admin                 = current_community.present? ? admin_communities_ids.include?(current_community.id) : false
    @is_manager               = current_community.present? ? attendant_communities_ids.include?(current_community.id) : false
    @is_committee             = current_community.present? ? committee_communities_ids.include?(current_community.id) : false
    @current_integration      = current_community&.integration
    @uses_period_control      = current_community&.uses_period_control?

    @repair = repair


    # Permisos exclusivos de administradores
    grant_exclusive_admin

    # AdministraFeliz user
    return if @user.id == 250

    # Ver index de permisos incluso sin comunidad
    can [:index], Permission

    return unless current_community.present? && (@is_manager || @is_admin || @is_committee) && !@repair

    can :details, ReferralProgramController if @current_community.present? && @current_community.country_code == 'CL' && @current_community.get_setting_value('referral_program') == 1

    permissions = user.permissions_in_community(current_community.id)
    @permission_by_code = {}
    Permission.code_names.each_key do |code|
      @permission_by_code[code] = permissions.detect { |p| p.code == code }
    end

    # Módulo de Copropietarios
    grant_property_user

    # Módulo de Recaudación
    grant_bills

    # Módulo de Ingresos Extraordinarios
    grant_income

    # Módulo de Cargos y Multas
    grant_property_fines unless @current_integration&.import_bills?

    # Módulo de Cargos agrupados
    grant_property_fine_groups unless @current_integration&.import_bills?

    # Módulo de Cargos recurrentes
    grant_debit_recurrences

    # Módulo de Egresos
    grant_service_billings

    # Módulo de Medidores
    grant_meters unless @current_integration&.import_bills?

    # Módulo de Remuneraciones
    can(:view_module_tab, Employee) if @is_admin || @permission_by_code['employees'].try(:view?)
    grant_employees if current_community.get_setting_value('remuneration') == 1 && %w[CL PE].include?(current_community.country_code)

    # Módulo Sendgrid
    grant_sendgrid if current_community.get_setting_value("sendgrid") == 1

    # Módulo Reportes
    grant_ayg if [1001, 1113, 1111, 1100, 1045, 1032, 1031, 1030, 1003, 1002, 973, 978, 894, 831, 800, 771, 1302].include?(current_community.id) #AyG, 831 candelaria

    # Módulo de Gastos Comunes
    grant_common_expenses

    # Módulo de Comunidad
    grant_community

    # Módulo de posts
    grant_posts

    # Módulo de Mantenimiento
    grant_maintenances

    # Módulo de Espacios Comunes
    grant_common_spaces if current_community.get_setting_value('common_spaces') > 0

    # Módulo de Libro de Visitas y Bitacora
    grant_guest_registry

    # Módulo de Encuestas
    grant_surveys

    # Módulo de Bitácora
    grant_logbook

    #Módulo de Encomiendas
    grant_package

    # Módulo de Publicidades
    grant_advertisements

    # Módulo de Incidencias
    grant_issues

    # Modulo de Facturación
    grant_billing

    # Override permissions if enabled_provisions settings is set.
    cannot :manage, Provision if (@current_community.get_setting_value('enabled_provisions') == 0 || @current_community.demo?)

    # Library Module
    grant_permissions_to_library

    # Mx Company global invoice
    grant_permission_to_global_invoice

    # STP promotion
    grant_permission_to_stp_promotion

    # Payments
    grant_permission_to_payments_views

    # Insurances
    grant_permission_to_insurances
  end

  def grant_exclusive_admin
    unless @admin_communities_ids.empty?
      # Manejo de permisos
      can [:nullify, :update, :update_profile, :user, :community, :remove_manager, :new_manager, :create_manager, :new_manager_partial], Permission

      #permisos para acceder a nueva interface
      can [:reject_new_interface,:active_new_interface, :rate_new_interface, :invitations, :change_new_interface], User

      # HubSpot tickets
      can :index, HubSpotTicketsController
    end

    if @current_community.present? && @is_admin
      return if @repair

      # Manejo de encargados
      editable_managers_ids = @user.get_managers.where(first_login: true).pluck(:id)
      view_managers_ids     = @user.get_managers.where(first_login: false).pluck(:id)

      can [:show], User do |u|
        @view_users_ids ||= @current_community.all_users.pluck(:id)
        view_managers_ids.include?(u.id) || @view_users_ids.include?(u.id)
      end

      can [:update, :new_existing_user], User do |u|
        editable_users_ids ||= @current_community.users.editable.pluck(:id)
        editable_managers_ids.include?(u.id) || editable_users_ids.include?(u.id)
      end

      can [:unify_bills, :properties], User do |u|
        @view_users_ids ||= @current_community.users.pluck(:id)
        @view_users_ids.include?(u.id)
      end

      # Fondos
      can [:new_funds, :create_funds], [Community] do |c|
        @admin_communities_ids.include?(c.id) && !@current_integration&.import_bills?
      end

      # Contactos
      can [:new_contacts, :create_contacts], [Community] do |c|
        @admin_communities_ids.include?(c.id)
      end
      # Propiedades
      can [:new_properties_select, :new_properties_excel, :new_properties_manual, :new_properties,
        :create_properties, :upload_data_properties, :preload_properties_from_excel,
        :import_properties_from_excel, :load_properties_directly_from_excel], [Community] do |c|
        @admin_communities_ids.include?(c.id)
      end
      can [:data_sample_properties_excel], [Community]

      # Property Param
      can [:edit, :show, :update, :destroy], PropertyParam do |p|
        @admin_communities_ids.include?(p.community_id)
      end
      can [:index, :new, :create], PropertyParam
      can [:index, :show, :update, :new, :destroy, :properties], PropertyFineGroup

      # Upselling
      if @current_community.country_code == 'CL'
        can [:buy, :after_buy, :info], Upselling
      end

      can :redirect_to_hire_demo, User if @current_community.demo? && @current_community.country_code.in?(%w[CL MX])

    end
  end

  def grant_billing
    return unless (@is_admin && @user.admin_communities.any?(&:active_billing)) || @permission_by_code['billing'].try(:edit?) ||
                  (@current_community.nil? && @user.admin_communities.any?(&:active_billing))

    can [:index, :postpone_block_date], Account

    can %i[index show], Contract if @is_admin || @permission_by_code['billing'].try(:edit?)

    # Un encargado no tiene permisos para editar la informacion de la cuenta
    unless @permission_by_code['billing'].try(:edit?)
      can %i[edit update], Account do |s|
        (@admin_communities_ids & s.communities.map(&:id)).present?
      end
    end

    can [:show, :pdf], Invoice do |i|
      @user.manageable_communities.preload(:accounts).map { |c| c.accounts.ids }.flatten.uniq.include?(i.account_id)
    end

    can %i[init_transaction_webpay results_transaction_webpay final_transaction], WebpayInvoicePaymentsController

    can %i[index billing], Invoice

    can %i[to_approve billing_confirmation rejected document approved receipt], InvoicePayment do |i_p|
      i_p.user_id == @user.id || @is_admin
    end

    if @current_community.country_code == 'CL'
      can %i[buy after_buy info], Upselling
    end
  end

  def grant_property_user
    if @is_admin || @permission_by_code['property_user'].try(:view?)
      can [:index, :aliquot_excel], Aliquot
      can [:index], [PropertyUser, Property, Transfer, PropertyUserRequest]
      can %i[confirm destroy download_ownership_document massive reject show undo], PropertyUserValidation

      # Ownership and identity documents uploads/removal
      can %i[remove_identity_documents update_documents], User do |user|
        (@admin_communities_ids & user.community_ids).any?
      end

      can %i[download_identity_document_zip], User do |user|
        user.any_identity_document_uploaded?
      end

      can [:search, :user_info], PropertyUser
      can %i[send_excel statement statement_not_nullified statement_summarized payments list_subproperties deactivate_old_properties show edit_payment payment_assignations], Property do |p|
        @communities_ids.include?(p.community_id)
      end
      can [:free_debt_certificate], PropertyUser do |p|
        @communities_ids.include?(p.property.community_id)
      end
      can [:interests, :debts, :show_debts], Property do |p|
        @communities_ids.include?(p.community_id) && !@current_integration&.import_bills?
      end
      can [:show], Debt do |s|
        @communities_ids.include?(s.community.id)
      end
      can [:show], AssignPayment do |s|
        @communities_ids.include?(s.community.id)
      end
      can [:show], Payment do |s|
        @communities_ids.include?(s.community.id)
        # @properties_ids.include?(s.property_id) # TODO revisar si esto funciona
      end
      can %i[show receipt bill short_bill split_bill update_day_of_month_to_notify_unrecognized_payments], Bill do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end

      can %i[show show_profile], Profile do |profile|
        profile.community_id == @current_community.id
      end

      can [:users_info], User

      can [:show, :properties], User do |u|
        @view_users_ids_residents ||= @current_community.all_users.pluck(:id)
        @view_users_ids_residents.include?(u.id)
      end
      can %i[setup_default_password notify_default_password without_email], PropertyUser do |s|
        @communities_ids.include?(s.community.id)
      end
    end

    if @is_admin || @permission_by_code['property_user'].try(:edit?)
      can %i[new create mass_update add_property_users get_groups_form list_subproperties import list_of_options_for_select], PropertyUser
      can [:group_update], PropertyUser if @current_community.get_setting_value('ass_enabled') == 1
      can %i[create destroy_all_old_properties has_valid_email pay_interests search_by_name toggle_pay_interests], Property
      can [:index, :update, :destroy, :aliquot_excel, :import], Aliquot
      can %i[new create_property_transfer create_subproperty_transfer import edit destroy related_properties related_subproperties properties_select], Transfer
      can [:edit, :update, :destroy, :toggle_active, :toggle_role, :set_in_charge], PropertyUser do |p|
        @communities_ids.include?(p.property.community_id)
      end
      can [:update], Property do |p|
        @communities_ids.include?(p.community_id)
      end
      can [:destroy], Property do |p|
        # sólo para propiedades enajenadas y sólo si la configuración lo permite.
        @communities_ids.include?(p.community_id) && p.property_transfers.blank? && p.old && @current_community.get_setting_value('allow_property_disabling') == 1
      end
      can [:destroy], Transfer do |t|
        @communities_ids.include?(t.period_expense.community_id)
      end
      can [:destroy_all_transfers], PeriodExpense do |p|
        @communities_ids.include?(p.community_id)
      end
      if @current_community.get_setting_value('delete_interest') == 1
        can [:destroy_interest], Property do |p|
          @communities_ids.include?(p.community_id)
        end
      end

      can [:update, :new_existing_user], User do |u|
        editable_users_ids ||= @current_community.users.editable.pluck(:id)
        editable_users_ids.include?(u.id)
      end

      can [:edit], User do |u|
        u.properties.pluck(:community_id).include?(@current_community.id)
      end

      can %i[edit edit_profile], Profile do |profile|
        profile.community_id == @current_community.id && profile.user.current_properties.pluck(:community_id).include?(@current_community.id)
      end

      can [:change_password, :change_email], User do |u|
        editable_users_ids ||= @current_community.users.editable.pluck(:id)
        editable_users_ids.include?(u.id) && u.first_login
      end

      can [:unify_bills], User do |u|
        @view_users_ids ||= @current_community.users.pluck(:id)
        @view_users_ids.include?(u.id)
      end

      can :index, PropertyParam
      can [:update, :edit, :new, :create, :destroy], PropertyParam do |p|
        @communities_ids.include?(p.community_id)
      end

      can [:confirm, :reject], PropertyUserRequest do |pur|
        @communities_ids.include?(pur.community.id)
      end

      can [:confirm, :reject], UserRequestQueries::UserRequest do |ur|
        @communities_ids.include?(ur.community.id)
      end

      permissions_to_excel_upload

    end
  end

  def grant_bills
    ass_enabled = @current_community.get_setting_value('ass_enabled') == 1
    if @is_admin || @permission_by_code['bills'].try(:view?)
      can :index, Integration::BillsController if @current_integration&.import_bills?

      can :collection_excel, Community

      can :update_day_of_month_to_notify_unrecognized_payments, Bill

      if @current_community.country_code == 'MX' && @current_community.get_setting_value('common_expense_fixed') > 0
        can :index, FutureStatement
        can :future_statement, Bill do |s|
          @communities_ids.include?(s.period_expense.community_id)
        end
      end

      unless @uses_period_control
        can %i[property_data], Async::NoPeriodBillsController
      end

      can :index, Bill unless @current_integration&.import_bills?

      can :index, [AccountSummarySheet, BundlePayment] if ass_enabled && !@current_integration&.import_bills?

      can %i[index unrecognized not_notified export_payments_excel show_modal], Payment

      can [:index], AssignPayment

      can %i[show receipt bill short_bill split_bill morosity], Bill do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
      can [:pdf_bills, :pdf_short_bills, :pdf_bills, :pdf_short_bills, :notify_pdf_payment_receipts, :pdf_payment_receipts], PeriodExpense do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:show], Debt do |s|
        @communities_ids.include?(s.community.id)
      end
      can [:show], AssignPayment do |s|
        @communities_ids.include?(s.community.id)
      end
      can [:show, :dispertions], Payment do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
      can [:statement, :statement_not_nullified, :statement_summarized, :payments, :missing_configurations], Property do |p|
        @communities_ids.include?(p.community_id)
      end

      can [:interests, :debts, :show_debts], Property do |p|
        @communities_ids.include?(p.community_id) && !@current_integration&.import_bills?
      end
      can [:show], BundlePayment do |p|
        # Dejar ver si pertenece a un periodo ya cerrado
        @communities_ids.include?(p.period_expense&.community_id) && ass_enabled && p.period_expense.common_expense_generated
      end
      can [:list_bills, :summary_sheet], AccountSummarySheet do |a|
        @communities_ids.include?(a.period_expense.community_id) && ass_enabled
      end

      # Descuentos por pagos adelantados en México
      if @current_community.country_code == 'MX'
        can [:show], FinkokResponse do |s|
          @communities_ids.include?(s.community&.id) || @communities_ids.include?(s.complement_community&.id)
        end
      end

      if @current_community.mx_company.present?
        can %i[email_billed_payments email_billed_payments_report irs irs_billed], MxCompany
        can %i[cancelled global notify show], FinkokResponse
      end

      # new interface access
      can %i[reject_new_interface active_new_interface rate_new_interface change_new_interface], User

      # business transactions
      can [:show], BusinessTransaction do |business_transaction|
        @communities_ids.include?(business_transaction.origin&.community&.id)
      end
    end

    if @is_admin || @permission_by_code['bills'].try(:edit?)
      can %i[has_valid_email], Property

      if ass_enabled
        can [:notify], AccountSummarySheet do |a|
          @communities_ids.include?(a.period_expense.community_id)
        end
        can %i[create import_data_sample import], BundlePayment
        can [:update, :nullify, :notify_voucher], BundlePayment do |p|
          @communities_ids.include?(p.period_expense&.community_id)
        end
        can [:pdf_grouped_bills, :pdf_mixed_bills], PeriodExpense do |p|
          @communities_ids.include?(p.community_id)
        end
      end

      unless @uses_period_control
        can %i[notify_statements collect_all_statements combined_statements bills_summary], Bill
        can %i[account_status property_account_statements update_last_pas], Property
        can %i[check_if_generated_pdf create notify], PropertyAccountStatement
        can %i[edit update], PropertyAccountStatementSetting
        can %i[property_data], Async::NoPeriodBillsController
      end

      if @current_community.country_code == 'MX' && @current_community.get_setting_value('common_expense_fixed') > 0
        can [:create], FutureStatement
        can [:delete, :notify, :bill], FutureStatement do |e|
          @communities_ids.include?(e.community.id)
        end
      end

      can %i[debt_assignation notify_debt_assignation], Debt
      can %i[notify_emails unclose_period_expense], Bill
      can [:validate_password], User do |user|
        # Only allow to validate my own password, not other users' one
        @user.id == user.id
      end
      can [:notify_pending, :new, :create], Payment
      can [:update_expiration_day], PeriodExpense
      can [:update, :pay, :split, :do_split, :notify], Bill do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
      can %i[notify_receipt bulk_notify_receipt notify_nullified edit update assign_payments set_exported check_if_generated_pdf hide_download hide], Payment do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end

      can %i[nullify raw_nullify], Payment do |p|
        !(%w[webpay online_payment spei].include? p.payment_type) && @communities_ids.include?(p.community.id)
      end

      can [:update, :set_balance, :pdf_salary_payments], PeriodExpense do |s|
        @communities_ids.include?(s.community_id)
      end

      can [:destroy], PurchaseOrderPayment

      can :import, Payment
      permissions_to_excel_upload

      # Descuentos por pagos adelantados en México
      if @current_community.country_code == 'MX'
        # MEXICO: facturar
        can %i[irs_all create cancel_irs create_complement irs_global], MxCompany if @current_community.mx_company.present?

        can [:cancel_irs_bill, :check_if_replacement_folio_valid], FinkokResponse do |s|
          @communities_ids.include?(s.community&.id) or @communities_ids.include?(s.complement_community&.id)
        end

        can %i[create], InternalBankingSetting
      end

      can [:update, :csd_key, :csd_cer], MxCompany do |s|
        @communities_ids.include?(s.community_id)
      end

      can [:notify_debts], Bill
      can %i[regenerate_receipt], Payment
    end

    unless @current_community.from_chile?
      if @is_admin || @user.admin? || @permission_by_code['bills'].try(:view?)
        can :index, Discount

        can :show, Discount do |discount|
          @communities_ids.include?(discount.period_expense&.community_id)
        end
      end

      if @is_admin || @user.admin? || @permission_by_code['bills'].try(:edit?)
        can %i[new create], Discount

        can %i[edit update destroy], Discount do |discount|
          @communities_ids.include?(discount.period_expense&.community_id)
        end
      end
    end
  end

  def grant_income
    if @is_admin || @permission_by_code['income'].try(:view?)
      can :index, Income
      can [:show], Income do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
    end

    if @is_admin || @permission_by_code['income'].try(:edit?)
      can [:new, :create], Income
      permissions_to_excel_upload
      can %i[edit update destroy_documentation destroy_receipt documentation receipt nullify import], Income do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
    end
  end

  def grant_property_fines
    if @is_admin || @permission_by_code['property_fines'].try(:view?)
      can [:index, :show], [PropertyFine, Fine, Surcharge]
      can [:surcharges, :deductions], Debt
      can [:configure, :preview], Surcharge
      can [:generate_excel], [PropertyFine, PropertyFineGroup]
    end

    if @is_admin || @permission_by_code['property_fines'].try(:edit?)
      can :import, PropertyFine
      permissions_to_excel_upload
      can [:new, :create], [PropertyFine, Fine, Surcharge, Deduction]
      can [:edit, :update, :destroy, :delete_multiple, :delete_with_fee_group, :notify], [PropertyFine, Fine] do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:edit, :update, :destroy, :create_from_configuration], Surcharge do |s|
        @communities_ids.include?(s.community.id)
      end

      can [:destroy, :update], Deduction
    end
  end

  def grant_property_fine_groups
    if @is_admin || @permission_by_code['property_fines'].try(:view?)
      can [:index, :show], [PropertyFineGroup, Fine]
    end

    if @is_admin || @permission_by_code['property_fines'].try(:edit?)
      can :import, PropertyFineGroup
      permissions_to_excel_upload
      can [:new, :create], [PropertyFineGroup, Fine]
      can [:edit, :update, :destroy, :delete_multiple, :delete_with_fee_group, :notify], [PropertyFineGroup, Fine] do |s|
        @communities_ids.include?(s.community_id)
      end
    end
  end

  def grant_debit_recurrences
    return if @uses_period_control

    if @is_admin || @permission_by_code['property_fines'].try(:view?)
      can [:index, :show], DebitRecurrence
    end

    if @is_admin || @permission_by_code['property_fines'].try(:edit?)
      can [:new, :create], DebitRecurrence
      can [:edit, :deactivate, :update, :destroy], DebitRecurrence do |s|
        @communities_ids.include?(s.community_id)
      end
    end
  end

  def grant_service_billings
    if @is_admin || @permission_by_code['service_billings'].try(:view?)
      can [:index, :aliquot_excel], Aliquot
      can [:index, :index_by_categories, :meters, :funds, :aliquots, :nullifieds, :summary, :group_summary, :check_uniq_supplier_sb, :year_excel, :month_excel, :import_data_sample, :no_period], ServiceBilling
      can :validate_rut, :validation
      can :view_open_period, ServiceBilling
      can [:index], [Supplier, Category, Provision]
      can [:search], Supplier
      can :index, [Checkbook, Check] if @current_community.get_setting_value('checkbook') == 1
      can [:show, :individual, :receipt, :bill, :details], ServiceBilling do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:show], [Supplier, Provision] do |s|
        @communities_ids.include?(s.community_id)
      end
    end

    if (@is_admin || @permission_by_code['service_billings'].try(:edit?)) && !@current_integration&.import_bills?
      permissions_to_excel_upload
      can %i[new create create_ocr_factura import denullify], ServiceBilling
      can [:create, :new, :edit], [Provision, ProvisionPeriodExpense, Supplier, Category]

      if @current_community.get_setting_value('checkbook') == 1
        can [:create, :new, :edit, :update], Checkbook
        can [:set_free, :nullify], Check
        can [:deactivate, :available_checks], Checkbook do |c|
          @communities_ids.include?(c.community_id)
        end
      end

      can %i[edit update nullify nullify_check toggle_paid toggle_paid_proratable undo_recurrent], ServiceBilling do |s|
        @communities_ids.include?(s.community_id)
      end
      can :move_fees, ServiceBillingFee do |s|
        @communities_ids.include?(s.community.id)
      end
      can [:destroy, :get_document], Asset do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:edit, :update, :destroy], [Supplier, Category] do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:edit, :update, :destroy, :import], Provision do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:update, :destroy], ProvisionPeriodExpense do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end

      permissions_to_excel_upload

    end
  end

  def grant_meters
    if @is_admin || @permission_by_code['meters'].try(:view?)
      can :index, [Mark, Meter]
      can [:year_excel, :month_excel], Mark
    end

    if @is_admin || @permission_by_code['meters'].try(:edit?)
      can [:new, :create], Meter
      can [:destroy, :create, :update, :delete_confirmation], Meter do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:update, :reset, :import], Mark do |s|
        @communities_ids.include?(s.period_expense.community_id)
      end
      permissions_to_excel_upload
    end
  end

  def grant_employees
    if @is_admin || @permission_by_code['employees'].try(:view?)
      can %i[index book get_previred download_lre], Employee
      can [:index], [Finiquito, Vacation, Advance, Salary, SalaryPayment]
      can %i[show seniority_certificate], Employee do |e|
        @communities_ids.include?(e.community_id)
        e.community_id == @current_community.id
      end
      can [:show, :document, :pdf], [Finiquito, SalaryPayment] do |s|
        @communities_ids.include?(s.employee.community_id)
      end
      can [:documentation, :voucher], [Vacation, Advance] do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:show, :contract_file], Salary do |s|
        @communities_ids.include?(s.employee.community_id)
      end
      can [:show, :individual, :receipt, :bill], ServiceBilling do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:pdf_salary_payments, :send_all_period_salary_payments, :pdf_advances], PeriodExpense do |s|
        @communities_ids.include?(s.community_id)
      end

      unless @current_community.ccaf == 'Sin CCAF'
        can [:index], [SocialCredit, SocialCreditFee]
        can [:show], SocialCredit do |e|
          @communities_ids.include?(e.employee.community_id)
        end
      end
    end

    if @is_admin || @permission_by_code['employees'].try(:edit?)
      can [:create, :new], [Employee, Finiquito, Vacation, Advance, Salary, SalaryPayment]
      can :get_indicators, SalaryPayment
      can [:update, :edit, :reactive, :destroy, :previred, :update_previred,
        :send_selected_salary_payments, :delete_photo, :statutory_declaration,
         :generate_statutory_declaration], Employee do |e|
        @communities_ids.include?(e.community_id)
        e.community_id == @current_community.id
      end
      can %i[update nullify preview calculate_vacation_days], Finiquito do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:edit, :update, :destroy, :destroy_documentation], [Vacation, Advance] do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:set_not_recurrent], Advance do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:update, :edit, :update_vacation_start_date], [Salary] do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:update, :edit, :nullify, :preview_modal, :upload_document], SalaryPayment do |e|
        @communities_ids.include?(e.employee.community_id)
      end
      can [:edit, :update, :update_bill], ServiceBilling do |s|
        @communities_ids.include?(s.community_id)
      end
      can [:destroy, :get_document], Asset do |s|
        @communities_ids.include?(s.community_id)
      end

      unless @current_community.ccaf == 'Sin CCAF'
        can [:create, :new], [SocialCredit, SocialCreditFee]
        can [:update, :edit], [SocialCredit] do |e|
          @communities_ids.include?(e.employee.community_id)
        end
        can [:destroy], SocialCredit do |sc|
          @communities_ids.include?(sc.employee.community_id)
        end
        can [:update, :destroy], SocialCreditFee do |e|
          @communities_ids.include?(e.period_expense.community_id)
        end
      end

      can %i[index create update worked_days reset], SalaryPaymentDraft
    end
  end

  def grant_sendgrid
    if @is_admin || @permission_by_code['sendgrid'].try(:view?)
      can %i[index index_problematic_mails index_unsent_mails problematic_mails_excel
             resend_problematic list_options_users_multiselect
             list_options_properties_multiselect], OutgoingMail
      can :fetch_mail_status, OutgoingMail do |om|
        @communities_ids.include?(om.community_id)
      end
    end
  end

  def grant_ayg
    can :regenerate_service_billings, Employee
  end

  def grant_common_expenses
    return false unless @current_community.get_setting_value('period_control') == 0

    if (@is_admin || @permission_by_code['common_expenses'].try(:view?))

      can %i[calculate view summary summary_xls index funds_detail], CommonExpense
      # Remove sample bill permission when no paid period expense in last 3 months
      can :sample, CommonExpense
      can [:statement, :statement_not_nullified, :statement_summarized, :payments], Property do |p|
        @communities_ids.include?(p.community_id)
      end

      can [:interests, :debts, :show_debts], Property do |p|
        @communities_ids.include?(p.community_id) && !@current_integration&.import_bills?
      end
    end

    if @is_admin || @permission_by_code['common_expenses'].try(:edit?)
      can [:new, :review, :verify, :validate, :recalculate], CommonExpense
      can [:validate_password], User do |user|
        # Only allow to validate my own password, not other users' one
        @user.id == user.id
      end
      can :period_expenses_registry, Community do |comm|
        @communities_ids.include?(comm.id)
      end
      can [:index, :edit, :update], PeriodExpense do |s|
        @communities_ids.include?(s.community_id)
      end
      can :import_bills, Integration if @current_integration&.import_bills?
      if @current_integration.present?
        can [:import_info, :api_import_transactions], Integration
      end
    end
  end

  def grant_community
    if @is_admin || @permission_by_code['community'].try(:view?)
      # Permisos de administradores y encargados
      can :index, FundTransfer
      can %i[index summary cash_flow view_module_tab], CommunityTransaction unless @current_integration&.import_bills?
      can :index, Budget
      can %i[index aliquot_excel], Aliquot
      can %i[fund print notify_free_debt_certificate], Property
      can %i[summary_excel index], :no_period_dashboard
      can %i[funds], Async::NoPeriodDashboardController
      can %i[property_data], Async::NoPeriodBillsController
      can %i[property property_history property_redirect common_expenses funds reserve_fund funds_excel admin work_in_progress], :dashboard
      can %i[grouped_morosity_letters morosity list_morosity show_service_billings], :dashboard unless @current_integration&.import_bills?

      can %i[create_massive_relations download_banred_refresh show property_user_validations_zip], Community do |community|
        @communities_ids.include?(community.id)
      end

      can %i[statement statement_not_nullified statement_summarized payments notify_pas resident_statement_view], Property do |p|
        @communities_ids.include?(p.community_id)
      end
      can %i[interests debts morosity_letter], Property do |p|
        @communities_ids.include?(p.community_id) && !@current_integration&.import_bills?
      end
      # Archivos adjuntos
      can :get_document, Asset do |s|
        @communities_ids.include?(s.community_id)
      end
      # Reportes de ingresos
      can :manage, Reports::IncomeOutcome
      # Reportes de balance
      can :manage, Reports::AnualBalance

      can %i[show], :demo_community
    end

    if @is_admin || @is_manager
      # Settings
      can :show, Setting do |s|
        @communities_ids.include? s.community_id
      end

      can %i[property_index pending_payments download_excel], Bill
    end

    if @is_admin || @permission_by_code['community'].try(:edit?)
      can %i[create update], BanredInfo
      can %i[create], Tour
      can %i[track_event], MixpanelController
      can %i[new create destroy], FundTransfer
      can %i[index update destroy aliquot_excel import], Aliquot
      can :edit_subproperties, Community
      unless @current_integration&.import_bills?
        can %i[close unclose preclose setup update_setup create new], CommunityTransaction # Strange bug
        can :automatic_bank_reconciliation, CommunityTransaction do |ct|
          ct.community&.country_code == 'CL'
        end
        can %i[new create budget_modal_form], Budget
        can %i[edit update], Budget do |b|
          @communities_ids.include?(b.period_expense.community_id)
        end
      end
      can %i[new create], Fund
      can %i[edit update delete_attach update_reserve_fund], Community do |s|
        @communities_ids.include?(s.id)
      end

      can :update, Setting do |s|
        @communities_ids.include?(s.community_id) && !Setting.admin_options.include?(s.code)
      end

      can :modify_community_transactions_date, Community do |s|
        @communities_ids.include?(s.id)
      end

      can :fully_modify_community_transactions, Community do |community|
        community.get_setting_value('manual_adjustment_in_bank_reconciliation').positive?
      end

      can :fully_modify_legacy_community_transactions, Community do |community|
        period_expense = community.current_bank_reconciliation
        (community.get_setting_value('custom_transactions').positive? || period_expense.first_bank_reconciliation)
      end

      can :list, TimeZone
      # tabs de edit de comunidad
      can :edit_tab, Community do |community, tab|
        @communities_ids.include?(community.id) &&
          case tab
          when :banred_info
            community.uruguayan?
          when :bill
            community.get_setting_value('period_control').zero?
          when :folio
            community.get_setting_value('folio').positive?
          when :interest
            community.get_setting_value('period_control').zero?
          when :remuneration
            community.get_setting_value('remuneration').positive? &&
              community.get_setting_value('period_control').zero?
          when :'payment-gateways'
            false
          when :'irs-mx'
            community.mx_company.present? || community.country_code == 'MX'
          when :'online-payment'
            (community.get_setting_value('online_payment').zero? ||
              community.online_payment_requests.present?) &&
              community.country_code == 'CL'
          else
            true
          end
      end
      can %i[update edit], CommunityTransaction do |e|
        @communities_ids.include?(e.community_id)
      end
      can %i[destroy update edit update_fund_period_expense], Fund do |f|
        @communities_ids.include?(f.community_id)
      end

      can %i[new new_remote create asset_url], Asset
      can %i[destroy silent_destroy], Asset do |s|
        @communities_ids.include?(s.community_id)
      end

      # Solicitud pago online
      can %i[request_online_payment], Community do |c|
        c.get_setting_value('online_payment').zero? &&
          c.country_code == 'CL' &&
          @communities_ids.include?(c.id)
      end
      can %i[list_online_payment_requests], Community do |c|
        (c.get_setting_value('online_payment').zero? || c.online_payment_requests.present?) &&
          c.country_code == 'CL' &&
          @communities_ids.include?(c.id)
      end

      can :update_online_payment_setting, Community do |c|
        @communities_ids.include?(c.id) && (c.payment_gateway_settings.present? || c.webpay_setting.present?)
      end

      can :show, OnlinePaymentRequest do |opr|
        @communities_ids.include?(opr.community_id)
      end
      can :cancel, OnlinePaymentRequest do |opr|
        @communities_ids.include?(opr.community_id) &&
          opr.pending?
      end

      # TODO: Revisar si esto va en View
      can :funds, :dashboard

      can :inactivate, CommunityUser do |cu|
        @communities_ids.include?(cu.community_id)
      end
      can [:manage, :set_default], BankAccount do |bank_account|
        @communities_ids.include?(bank_account.community_id)
      end
      can :update_rut, Community do
        @user.admin?
      end
    end
  end

  def grant_posts
    if @is_admin || @permission_by_code['posts'].try(:view?)
      can %i[index unpublished download_pdf], Post
      can :show, Conference do |conf|
        @communities_ids.include?(conf.post.community_id)
      end
    end

    if @is_admin || @permission_by_code['posts'].try(:edit?)
      can %i[attachments_list new create asset_url], Post
      can %i[get_file edit update destroy destroy_file], Post do |s|
        @communities_ids.include?(s.community_id)
      end
    end

    can :manage, PostTemplate
  end

  def grant_maintenances
    if @is_admin || @permission_by_code['maintenances'].try(:view?)
      can [:index], [Maintenance, Installation]
      can [:show], Installation do |i|
        @communities_ids.include?(i.community_id)
      end
      can [:show, :task_file, :task_file_completed], Maintenance do |m|
        @communities_ids.include?(m.installation.community_id)
      end
    end

    if @is_admin || @permission_by_code['maintenances'].try(:edit?)
      can [:create, :new], [Maintenance, Installation]
      can [:update, :destroy, :show, :edit], Installation do |i|
        @communities_ids.include?(i.community_id)
      end
      can [:update, :destroy, :show, :edit], Maintenance do |m|
        @communities_ids.include?(m.installation.community_id)
      end
    end
  end

  def grant_common_spaces
    if @is_admin || @permission_by_code['common_spaces'].try(:view?)
      can [:index], [CommonSpace, Event]
      can %i[get_full_slot show], CommonSpace do |cs| # CommonSpace Admin
        @communities_ids.include?(cs.community_id)
      end
    end

    if @is_admin || @permission_by_code['common_spaces'].try(:edit?)
      can [:new, :create], [CommonSpace, Event]
      can [:update, :destroy, :edit, :search, :toggle_availability], CommonSpace do |cs| # CommonSpace Admin
        @communities_ids.include?(cs.community_id)
      end
      can [:edit, :update, :confirm, :reject, :destroy], Event do |ev| # Event Admin
        @communities_ids.include?(ev.common_space.community_id)
      end

      can :cancel, Event do |ev|
        @communities_ids.include?(ev.common_space.community_id) && ev.user == @user
      end
    end
  end

  # GUEST REGISTRY
  def grant_guest_registry
    if @is_admin || @permission_by_code['guest_registry'].try(:view?)
      # can [:index], AccessControlController
      can [:index, :last_guest_registry, :guest_list], GuestRegistry
      can %i[show send_invitation], [GuestRegistry] do |p|
        @communities_ids.include?(p.community_id)
      end
      can [:show], [BlackListGuest] do |p|
        @communities_ids.include?(p.community.id)
      end
      can :show_invitation, GuestRegistry do |p|
        p.provider?
      end
      can :index, [Property, BlackListGuest]
    end
    if @is_admin || @permission_by_code['guest_registry'].try(:edit?)
      can %i[import import_data_sample], GuestRegistry
      permissions_to_excel_upload
      can [:new, :create], [GuestRegistry, BlackListGuest, Logbook]
      can [:edit, :update, :destroy, :restore], [GuestRegistry] do |p|
        @communities_ids.include?(p.community_id)
      end
      can [:edit, :update, :destroy, :restore], [BlackListGuest] do |p|
        @communities_ids.include?(p.community.id)
      end
      can [:edit, :update, :destroy], Logbook do |l|
        @communities_ids.include?(l.community_id)
      end
      can [:notify, :set_attended, :code_scanner, :check_invitation], GuestRegistry do |p|
        @communities_ids.include?(p.community_id)
      end

      can [:destroy], GuestEntry

      # Access Contrl
      return unless @current_community.access_control_enabled?
      can [:index], AccessControlController
    end
  end

  # SURVEYS
  def grant_surveys
    if @is_admin || @permission_by_code['surveys'].try(:view?)
      can [:index], [Option, Question, Survey]

      can [:show_votes, :results], Survey do |s|
        @communities_ids.include?(s.community_id)
      end

      can :search, Question
    end

    if @is_admin || @permission_by_code['surveys'].try(:edit?)
      can [:create], [Question, Option, Survey]

      can [:edit, :update, :destroy, :publish, :publish_results, :close_early, :draft_destroy, :save_options_title], Survey do |s|
        @communities_ids.include?(s.community_id)
      end

      can [:update, :destroy, :add_asset, :destroy_asset], Question do |q|
        @communities_ids.include?(q.survey.community_id)
      end

      can [:update, :destroy], Option do |o|
        @communities_ids.include?(o.question.survey.community_id)
      end

    end
  end

  # ADVERTISEMENTS
  def grant_advertisements
    can [:show], Advertisement do |a|
      @user.advertisements.ids.include?(a.id)
    end
    can [:show], AdvertisementUser do |a|
      @user.advertisement_users.ids.include?(a.id)
    end
    can [:toggle_active, :visit_advertisement], AdvertisementUser do |a|
      @user.advertisement_users.ids.include?(a.id)
    end
  end

  def grant_logbook
    if @is_admin || @permission_by_code["logbook"].try(:view?)
      can :index, Logbook
      can [:show], Logbook do |l|
          @communities_ids.include?(l.community_id)
      end
    end

    if @is_admin || @permission_by_code["logbook"].try(:edit?)
      can :create, Logbook
      can [:edit, :update, :destroy, :notifiable], Logbook do |l|
        @communities_ids.include?(l.community_id)
      end
      can [:notify], Logbook do |log|
        @communities_ids.include?(log.community_id) & Logbook.notifiable(log.property_id)
      end
    end
  end

  def grant_package
    if @is_admin || @permission_by_code['logbook'].try(:view?)
      can %i[index property_users add_employee bulk_reception], Package
      can %i[show restore employees download property_users], Package do |package|
        @communities_ids.include?(package.community_id)
      end
      can %i[show restore download], Collaborators::PackageEmployee do |package|
        @communities_ids.include?(package.community_id)
      end
    end

    return unless @is_admin || @permission_by_code['logbook'].try(:edit?)

    can %i[create property_users add_employee], Package
    can %i[edit restore update destroy deactivate undo], Package do |package|
      @communities_ids.include?(package.community_id)
    end
    can %i[create update edit deactivate], Collaborators::PackageEmployee do |package|
      @communities_ids.include?(package.community_id)
    end
  end

  def permissions_to_excel_upload
    can %i[show], ExcelUpload
    can %i[create import_data], ExcelUpload
    can %i[download_template_file], ExcelUpload
  end

  def grant_issues
    if @is_admin || @permission_by_code['issues'].try(:view?)
      can %i[index opened closed started], Issue
      can [:show], Issue do |s|
        @communities_ids.include?(s.community_id)
      end
    end

    if @is_admin || @permission_by_code['issues'].try(:edit?)
      can [:new, :new_remote, :create, :update], Asset

      can %i[index new create opened started closed], Issue
      can %i[update view edit pre_close destroy attachments_list set_started open_modal_accountable], Issue do |s|
        @communities_ids.include?(s.community_id)
      end
    end

    if @is_admin || @permission_by_code['issues'].try(:issues_accountable?)
      can %i[index opened started closed], Issue
      can %i[new new_remote create], Asset
      can %i[view set_started pre_close update destroy], Issue do |issue|
        issue.accountable_id == @user.id || @is_admin
      end
    end
  end

  def grant_permissions_to_library
    can %i[show index download], LibraryFile

    can %i[new create edit update destroy notify_residents], LibraryFile if @is_admin || (@is_manager && can?(:edit, Community))
  end

  def grant_permission_to_global_invoice
    return unless @current_community.country_code == 'MX'

    can %i[set_user_identification_data], MxCompany
  end

  def grant_permission_to_stp_promotion
    return unless @current_community.is_mexican?

    can %i[stp_promotion stp_requirements send_requirements_stp], Upselling
  end

  def grant_permission_to_payments_views
    can %i[index destroy enrollment_card subscription_failure subscription_success subscribe unsubscribe tour update_ocs_tour_user_flag], :automatic_online_payments
    can %i[new create callback success error faq checkout], :online_payments
    can %i[create], :kushki_mx
    can %i[create destroy callback], :online_payment_cards
    can %i[create unrollment], :periodic_online_payments
  end

  def grant_permission_to_insurances
    return unless @current_community.from_chile?

    can %i[index request_quote], :insurances
  end
end
