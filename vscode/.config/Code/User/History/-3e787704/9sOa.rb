DefaultInit::Application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
    mount Lookbook::Engine, at: '/lookbook'
  end

  post 'stp/abono', to: 'stp/webhooks#abono'
  post 'stp/estado', to: 'stp/webhooks#estado'
  ###### OneClick #####
  get 'one_click_subscription'                  => 'one_click_subscriptions#index'
  get 'one_click_subscription_tour'             => 'one_click_subscriptions#tour'
  patch 'update_ocs_tour_user_flag'             => 'one_click_subscriptions#update_ocs_tour_user_flag'
  delete 'one_click_subscription/:card_id'      => 'one_click_subscriptions#destroy'
  get 'one_click_subscription_failure'          => 'one_click_subscriptions#subscription_failure'
  get 'one_click_subscription_success'          => 'one_click_subscriptions#subscription_success'
  post 'one_click_subscription/subscribe'       => 'one_click_subscriptions#subscribe'
  post 'one_click_subscription/unsubscribe'     => 'one_click_subscriptions#unsubscribe'
  post 'one_click_subscription/enrollment_card' => 'one_click_subscriptions#enrollment_card'

  get '/copropietario/property_page_pending', to: 'custom_errors#property_page_pending'

  post '/graphql', to: 'graphql#execute'

  # React
  get '/v2/password_recovery', to: 'sessions#recover_password', as: 'recover_password'

  # Routes for Google authentication
  get 'oauth/:provider/init', to: 'sessions#oauth'
  get 'oauth/:provider/callback', to: 'sessions#create_with_oauth'
  get 'oauth/failure', to: redirect('/')

  # access to new interface
  put 'reject_new_interface' => 'users#reject_new_interface', as: 'reject_new_interface'
  put 'active_new_interface' => 'users#active_new_interface', as: 'active_new_interface'
  put 'rate_new_interface'   => 'users#rate_new_interface',   as: 'rate_new_interface'

  # Facebook auth
  delete 'facebook_auth_destroy_user' => 'users#facebook_auth_destroy_user', as: 'facebook_auth_destroy_user'
  get    'opt-out-facebook'           => 'users#facebook_auth_opt_out',      as: 'facebook_auth_opt_out'

  # 2FA
  get    'two_factor_authentication' => 'user_mfa_session#new',     as: 'new_user_mfa_session'
  post   'two_factor_authentication' => 'user_mfa_session#create',  as: 'user_mfa_session'
  delete 'two_factor_authentication' => 'user_mfa_session#destroy', as: 'destroy_user_mfa_session'

  ###### DASHBOARD ######
  get 'panel/administrador'      => 'dashboard#admin',                    as: 'dashboard'
  get 'panel/morosidad'          => 'dashboard#morosity',                 as: 'morosity'
  get 'panel/listar_morosidad'   => 'dashboard#list_morosity',            as: 'list_morosity'
  get 'panel/cartas_morosidad'   => 'dashboard#grouped_morosity_letters', as: 'grouped_morosity_letters'
  get 'panel/propiedad'          => 'dashboard#property',                 as: 'property_dashboard'
  get 'redirigir_propiedad'      => 'dashboard#property_redirect',        as: 'property_redirect'
  get 'panel/inmobiliaria'       => 'dashboard#real_estate',              as: 'real_estate_dashboard'
  get 'panel/gastos_comunes'     => 'dashboard#common_expenses',          as: 'common_expenses_dashboard'
  get 'panel/fondos_adicionales' => 'dashboard#funds',                    as: 'funds_dashboard'
  get 'panel/fondo_reserva'      => 'dashboard#reserve_fund',             as: 'reserve_fund_dashboard'
  get 'panel/historial'          => 'dashboard#property_history',         as: 'property_history'
  get 'panel/mantencion'         => 'dashboard#work_in_progress',         as: 'work_in_progress'
  get 'panel/mostrar_egresos'    => 'dashboard#show_service_billings',    as: 'show_service_billings'

  ###### NO PERIOD CONTROL DASHBOARD ######
  get 'panel/fondos'                 => 'no_period_dashboard#index',    as: 'no_period_funds_dashboard'
  get 'panel/resumen_de_movimientos' => 'no_period_dashboard#summary_excel',    as: 'no_period_funds_summary_excel'

  ###### WEBPAY ######
  post 'webpay/webpay_init'                => 'webpay#init_transaction_webpay',                     as: 'init_webpay'
  get 'webpay/webpay_error'                => 'webpay#webpay_error',                                as: 'webpay_error'
  post 'webpay/results_transaction_webpay' => 'webpay#results_transaction_webpay',                  as: 'webpay_transaction'
  post 'webpay/final_transaction'          => 'webpay#final_transaction',                           as: 'final_transaction'
  post 'pago/resultados'                   => 'webpay_invoice_payments#results_transaction_webpay', as: 'webpay_pago_transaction'
  post 'pago/final'                        => 'webpay_invoice_payments#final_transaction',          as: 'final_pago_transaction'
  get 'pago/webpay'                        => 'webpay_invoice_payments#init_transaction_webpay',    as: 'init_pago_webpay'
  get 'panel/excel_fondos'                 => 'dashboard#funds_excel',                              as: 'funds_excel_dashboard'
  get 'webpay/inicio'                      => 'webpay_payments#init_transaction_webpay',            as: 'webpay_payments_init'
  post 'webpay/resultados'                 => 'webpay_payments#results_transaction_webpay',         as: 'webpay_payments_results'
  post 'webpay/final'                      => 'webpay_payments#final_transaction',                  as: 'webpay_payments_final'
  get 'webpay/exito'                       => 'webpay_payments#success',                            as: 'webpay_payments_success'
  get 'webpay/error'                       => 'webpay_payments#error',                              as: 'webpay_payments_error'

  post 'portaldepagos/campaign_checkout' => 'portal_de_pagos#campaign_checkout', as: :portal_de_pagos_campaign_checkout
  post 'portaldepagos/checkout' => 'portal_de_pagos#checkout', as: :portal_de_pagos_checkout
  get 'portaldepagos/fatal' => 'portal_de_pagos#fatal', as: :portal_de_pagos_fatal
  get 'portaldepagos/document/:id' => 'portal_de_pagos#show', as: :portal_de_pagos_document
  get 'portaldepagos/check_only_show_one_click_setting' => 'portal_de_pagos#check_only_show_one_click_setting'
  delete 'portaldepagos/destroy/:id' => 'portal_de_pagos#destroy', as: :portal_de_pagos
  patch 'portaldepagos/update_property_automatic_payment' => 'portal_de_pagos#update_property_automatic_payment'

  get 'portaldepagos/success' => 'portal_de_pagos#success'
  get 'portaldepagos/error' => 'portal_de_pagos#error', as: :portal_de_pagos_error
  get 'portaldepagos/cancelled' => 'portal_de_pagos#cancelled', as: :portal_de_pagos_cancelled
  get 'portaldepagos/pending' => 'portal_de_pagos#pending', as: :portal_de_pagos_pending

  get 'invitation/:token' => 'guest_registries#invitation', as: 'invitation'
  patch 'invitation/:token' => 'guest_registries#self_generate_qr', as: 'self_generate_qr'

  ###### VIRTUAL ASSISTANT ######
  get 'asistente_virtual' => 'period_warnings', as: :period_warning, to: 'period_warnings#index'
  # Upselling

  resources :usage_interactions, path: 'actividades_y_objetivos', only: [:index] do
    collection do
      get 'download_certificate', action: 'download_certificate', as: 'download_certificate'
      post 'send_online_payment_manual', action: 'send_online_payment_manual', as: :send_online_payment_manual
      post 'enable_kushki_request', action: 'enable_kushki_request', as: :enable_kushki_request
    end
  end

  get 'upselling/after_buy/:package' => 'upselling#after_buy', as: :upselling_after_buy
  get 'upselling/info/:package' => 'upselling#info', as: :upselling_info
  get 'upselling/irs_promotion'
  post 'upselling/buy/:package' => 'upselling#buy', as: :upselling_buy
  get 'stp_activacion' => 'upselling#stp_promotion', as: :upselling_stp
  get 'stp_requisitos' => 'upselling#stp_requirements', as: :upselling_stp_requirements
  post 'enviar_requisitos_stp' => 'upselling#send_requirements_stp', as: :upselling_send_requirements_stp

  # Insurance
  get 'seguros' => 'insurances#index', as: :insurances
  post 'cotizar_seguros' => 'insurances#request_quote', as: :insurances_request_quote

  # HubSpot tickets
  get 'tickets' => 'hub_spot_tickets#index', as: :hub_spot_tickets

  resources :certificates do
    collection do
      get 'happy_seal/:client_user_id', action: 'super_admin_happy_seal', as: 'super_admin_happy_seal'
      get 'happy_seal', action: 'admin_happy_seal', as: 'admin_happy_seal'
      get 'validate/:alphanumeric_code', action: 'validate', as: 'validate'
      get 'download_happy_seal_pdf/:alphanumeric_code', action: 'download_happy_seal_pdf', as: 'download_happy_seal_pdf'
      get 'raw_html/:alphanumeric_code', action: 'raw_html', as: 'raw_html'
    end
    member do
      get 'check_if_happy_seal_generated_pdf'
    end
  end
  get 'programa_referidos' => 'referral_program#details', as: 'referral_program'
  get 'self_granted_permissions', action: 'self_granted_permissions', controller: 'superadmin_permissions'

  resources :contracts, only: %i[index show]

  resources :points do
    collection do
      get 'render_heatmap'
    end
  end

  resources :banred_infos, only: %i[create update]

  resources :buy_orders, path: 'ordenes', only: [:index] do
    member do
      get 'inicio' => 'buy_orders#init_transaction', as: 'init_transaction'
    end
    collection do
      get 'final' => 'buy_orders#final_transaction', as: 'final_transaction'
      get 'generic_error' => 'buy_orders#generic_error', as: 'generic_error'
    end
  end

  resources :products, path: 'productos' do
    member do
      post 'prepare_buy_order'
    end
  end

  resources :remote_modals, only: [] do
    collection do
      get 'event_actions', defaults: { format: :js }
    end
  end

  resources :mx_companies, only: %i[update create] do
    collection do
      post 'create_complement'
      get 'irs_all'
      post 'irs_all'
      post 'irs_global'
      get 'irs'
      get 'irs_billed'
      post 'email_billed_payments'
      post 'email_billed_payments_report'
      get 'set_user_identification_data'
    end
    member do
      get 'csd_cer'
      get 'csd_key'
    end
  end

  get 'check_if_replacement_folio_valid', to: 'finkok_responses#check_if_replacement_folio_valid'
  resources :finkok_responses, only: [:show] do
    collection do
      get 'cancelled'
      post 'cancel_irs_bill'
      get 'global'
    end
    member do
      post 'notify'
    end
  end

  # Suppliers
  resources :suppliers, path: 'proveedores' do
    collection do
      get 'search'
    end
  end
  resources :categories, path: 'categorias' do
    collection do
      post :destroy_with_migration
      get :load_categories_without_paginate, as: 'list_without_paginate'
    end
  end

  # Guest Book

  resources :provisions, path: 'provisiones' do
    resources :provision_period_expenses, only: %i[create update destroy]
  end

  # Access Control

  resources :access_control, only: %i[index]

  # resources :service_billing_templates do
  # end

  resources :funds, path: 'fondos', only: %i[show destroy new update create edit] do
    member do
      get 'actualizar', as: 'update_fund_period_expense'
    end
  end

  # rutas para pagos en nuevo portal de pagos
  get 'online_payments/:id/callback' => 'online_payments#callback'
  get 'online_payments/:id/success'  => 'online_payments#success'
  get 'online_payments/:id/pending'  => 'online_payments#pending'
  get 'online_payments/:id/error'    => 'online_payments#error'

  resources :online_payments, only: %i[new create] do
    collection do
      post :checkout
      get :faq
    end
  end

  # rutas para pagos en nuevo portal de pagos
  get  'online_easy_pay/:id/callback' => 'online_easy_pay#callback'
  get  'online_easy_pay/:id/success'  => 'online_easy_pay#success'
  get  'online_easy_pay/:id/error'    => 'online_easy_pay#error'
  get  'online_easy_pay/faq'          => 'online_easy_pay#faq'
  get  'online_easy_pay/new'          => 'online_easy_pay#new'
  post 'online_easy_pay/create'       => 'online_easy_pay#create'

  resources :automatic_online_payments, only: %i[index] do
    collection do
      post 'subscribe'
      post 'unsubscribe'
    end
  end
  get 'automatic_online_payment_tour'             => 'automatic_online_payments#tour'
  get 'automatic_online_payment_failure'          => 'automatic_online_payments#subscription_failure'
  get 'automatic_online_payment_success'          => 'automatic_online_payments#subscription_success'
  patch 'update_ocs_tour_user_flag_aop'           => 'automatic_online_payments#update_ocs_tour_user_flag'
  post 'kushki_mx/create'                         => 'kushki_mx#create'
  post 'f_pay/create'                             => 'f_pay#create'

  post 'periodic_online_payments'                 => 'periodic_online_payments#create'
  delete 'periodic_online_payments/unrollment'    => 'periodic_online_payments#unrollment'


  # rutas para afiliacion de tarjetas con nuevo portal de pagos y pago directo afiliando en una sola transaccion
  get    'online_payment_cards/callback'      => 'online_payment_cards#callback'
  post   'online_payment_cards'               => 'online_payment_cards#create'
  delete 'online_payment_cards/:id'           => 'online_payment_cards#destroy'

  resources :online_payment_requests, path: 'solicitudes_pago_online', only: %i[show] do
    member do
      patch 'cancel'
    end
  end

  resources :fund_transfers, path: 'transferencias_fondos', only: %i[index new create destroy]
  resources :community_transactions, path: 'transacciones' do
    collection do
      post 'close'
      get 'preclose'
      get 'unclose'
      get 'resumen', as: 'summary', action: 'summary'
      get 'flujo_caja', as: 'cash_flow', action: 'cash_flow'
      get 'saldo_en_caja', as: 'bank_status', action: 'cash_flow', defaults: { tab: :bank_status }
      get 'estado_presupuestario', as: 'budget', action: 'cash_flow', defaults: { tab: :budget }
      get 'setup'
      patch 'update_setup'
      get 'automatic_bank_reconciliation', as: 'automatic_bank_reconciliation', action: 'automatic_bank_reconciliation'
    end
  end

  post 'uploader/image', to: 'uploaders#image'

  get 'service_billings/check_uniq_supplier_sb'
  resources :service_billings, path: 'egresos' do
    resources :assets, only: :destroy, path: 'archivos'
    resources :service_billing_fees, path: 'cuotas' do
      member do
        put 'mover_cuotas', as: 'move_fees', action: 'move_fees'
      end
    end
    collection do
      get 'categorias', as: 'index_by_categories', action: 'index_by_categories'
      get 'consumo_individual', as: 'meters', action: 'meters'
      get 'fondos', as: 'funds', action: 'funds'
      get 'alicuotas', as: 'aliquots', action: 'aliquots'
      get 'anulados', as: 'nullifieds', action: 'nullifieds'
      get 'no_period', action: 'no_period'
      get 'categories_typeahead'
      get 'individual'
      get 'chequera'
      get 'year_excel'
      get 'month_excel'
      post 'summary'
      post 'group_summary'
      get 'importar', as: 'import_data_sample', action: 'import_data_sample'
    end
    member do
      delete 'nullify'
      get 'nullify_check'
      patch 'update_bill'
      patch 'denullify'
      get 'receipt'
      get 'bill'
      get 'restablecer_cheques', as: 'reset_checks_periods', action: 'reset_checks_periods'
      post 'toggle_paid'
      post 'toggle_paid_proratable'
      post 'undo_recurrent'
      get 'details'
    end
  end

  resources :assets, only: %i[new create], path: 'archivos' do
    collection do
      get 'new_remote'
      post 'asset_url'
    end
    member do
      get 'get_document'
      delete 'silent_destroy'
    end
  end

  resources :period_expenses, only: [:update] do
    member do
      patch 'set_balance'
      delete 'destroy_all_transfers'
      get 'send_all_period_salary_payments'
      # PDF
      get 'pdf_grouped_bills'
      get 'pdf_mixed_bills'
      get 'pdf_bills'
      get 'pdf_salary_payments'
      get 'pdf_short_bills'
      get 'pdf_advances'
      get 'notify_pdf_payment_receipts'
      get 'pdf_payment_receipts'
    end
  end

  resources :bills, path: 'boletas', only: %i[show index update] do
    collection do
      get 'notify_emails'
      get 'unclose_period_expense'
      get 'rebuild_all_bills'
      post 'notify_debts'
      get 'morosity'
      get 'property_index'
      get 'pending_payments'
      get 'download_excel', constraints: { format: :xlsx }
      post 'update_day_of_month_to_notify_unrecognized_payments'
    end
    member do
      get 'split'
      post 'do_split'
      get 'notify'
      get 'reconstruct_pdf'
      # PDF AWS
      get 'receipt'
      get 'bill'
      get 'short_bill'
      get 'split_bill'
      get 'public_bill/:token', action: 'public_bill', as: 'public_bill'
    end
  end

  resources :no_period_bills, only: [:index] do
    collection do
      get 'bills_summary'
      get 'combined_statements'
      get 'collect_all_statements'
      post 'notify_statements'
      get 'morosity'
    end

    member do
      get 'split'
      post 'do_split'
      get 'notify'
      get 'reconstruct_pdf'
      # PDF AWS
      get 'receipt'
      get 'bill'
      get 'short_bill'
      get 'split_bill'
      get 'public_bill/:token', action: 'public_bill', as: 'public_bill'
    end
  end

  # FUTURE STATEMENT MODULE was deprecated in WEB-6799 ticket
  # resources :future_statements, path: "estado_cuenta_futuro", only: [:create, :index, :delete] do
  #   member do
  #     get 'bill'
  #     get 'notify'
  #   end
  # end

  resources :account_summary_sheets, path: 'boletas_agrupadas', only: [:index] do
    member do
      get 'notify'
      get 'rebuild'
      get 'list_bills'
      get 'summary_sheet'
      get 'public/:token', action: 'public_summary_sheet', as: 'public_summary_sheet'
    end
  end

  post '/period/update_expiration_day' => 'period_expenses#update_expiration_day', as: 'update_expiration_day'

  resources :common_expenses, path: 'gastos_comunes', only: [] do
    collection do
      get 'calcular', as: 'calculate', action: 'calculate'
      get 'resumen', as: 'summary', action: 'summary'
      match 'verificar', as: 'verify', action: 'verify', via: %i[get post]
      post 'validate'
      get 'view'
      get 'sample'
      get 'summary_xls'
      get 'recalculate'
      get 'funds_detail'
    end
  end

  resources :properties, path: 'propiedades', only: %i[index destroy update create edit new] do
    member do
      get 'statement'
      get 'statement_not_nullified'
      get 'statement_summarized'
      get 'interests'
      get 'debts'
      get 'payments'
      get 'destroy_interest'
      get 'destroy_business_transaction'
      get 'morosity_letter'
      get 'notify_pas'
      get 'list_subproperties'
      post 'toggle_pay_interests'
      get 'account_status'
      get 'update_last_pas'
      get 'property_account_statements'
      post 'generate_pas_forcefully'
      get 'missing_configurations'
      get 'notify_free_debt_certificate'
      get 'resident_statement_view'
    end

    collection do
      get 'pay_interests'
      get 'send_excel'
      get 'search_by_name'
      get 'fund'
      get 'print'
      get 'propiedades_enajenadas', as: 'deactivate_old_properties', action: 'deactivate_old_properties'
      delete 'destroy_all_old_properties'
      post 'generate_pas_forcefully_all'
      get 'has_valid_email'
      get 'edit_payment'
      get 'payment_assignations'
    end
  end

  resources :property_account_statements, only: [:create]

  resources :transfers, path: 'transferencias', only: %i[index destroy new] do
    collection do
      get 'related_properties'
      get 'related_subproperties'
      get 'properties_select'
      post 'create_property_transfer'
      post 'create_subproperty_transfer'
    end
  end

  resources :marks, path: 'marcas', only: %i[index update show] do
    member do
      put 'reset'
    end
    collection do
      get 'year_excel'
      get 'month_excel'
    end
  end

  resources :meters, path: 'medidores', only: %i[index create destroy update] do
    collection do
      get 'confirmacion', as: 'delete_confirmation', action: 'delete_confirmation'
    end
  end

  resources :property_users, path: 'copropietarios' do
    member do
      get  'free_debt_certificate'
      post 'toggle_active'
      post 'toggle_role'
      post 'set_in_charge'
    end
    collection do
      get 'user_info'
      get 'add_property_users'
      get 'search'
      post 'get_groups_form'
      post 'mass_create'
      post 'mass_update'
      post 'group_update'
      get 'group_all'
      post 'notify_default_password'
      get 'setup_default_password'
      get 'without_email'
      get 'list_of_options_for_select'
    end
  end

  resources :property_user_requests, only: [:index] do
    member do
      put 'confirm'
      put 'reject'
    end
  end

  resources :property_user_validations, only: %i[show destroy] do
    member do
      put 'confirm'
      put 'reject'
      put 'undo'
      get 'download_ownership_document'
    end
    collection do
      get 'massive'
    end
  end

  resources :property_fines, path: 'cargos' do
    collection do
      delete 'delete_multiple'
      get 'generate_excel'
    end

    member do
      post 'notify'
      delete 'delete_with_fee_group'
    end
  end

  resources :property_fine_groups, path: 'cargos_agrupados' do
    collection do
      get 'properties'
      get 'generate_excel'
    end

    member do
      post 'notify'
    end
  end

  resources :surcharges, path: 'recargos' do
    collection do
      get 'configurar', to: 'surcharges#configure', as: 'configure'
      get 'previsualizar', to: 'surcharges#preview', as: 'preview'
      post 'create_from_configuration'
    end
  end

  resources :advertisement_users, only: %i[visit_advertisement toggle_active], path: 'noticias' do
    member do
      patch 'visit_advertisement'
      patch 'toggle_active'
    end
  end
  resources :property_params

  resources :fines, path: 'plantilla_de_cargos'

  resources :communities, path: 'comunidades' do
    member do
      get 'past_administrators'
      post 'update_data_after_preview'
      get 'change_account'
      get 'avatar'
      get 'signature'
      get 'company_image'
      get 'crear_fondos', as: 'new_funds', action: 'new_funds'
      post 'create_funds'
      get 'crear_contactos', as: 'new_contacts', action: 'new_contacts'
      post 'create_contacts'
      get 'download_banred_refresh'
      get 'opciones_propiedades', as: 'new_properties_select', action: 'new_properties_select'
      get 'excel_propiedades', as: 'new_properties_excel', action: 'new_properties_excel'
      get 'propiedades_manual', as: 'new_properties_manual', action: 'new_properties_manual'
      post 'create_properties'
      post 'upload_data_properties'
      post 'propiedades_importadas', as: 'preload_properties_from_excel', action: 'preload_properties_from_excel'
      post 'preview_excel', as: 'import_properties_from_excel', action: 'import_properties_from_excel'
      post 'load_properties_directly_from_excel'
      post 'update_reserve_fund'
      post 'add_committee_member'
      get 'modo_trabajo', as: 'maintenance_mode', action: 'maintenance_mode'
      delete 'delete_attach'
      get 'period_expenses_registry'
      get 'collection_excel'
      get 'property_user_validations_zip'
      post 'activate_new_payments_portal'
      patch 'deactivate_new_payments_portal'
      get 'create_massive_relations'
    end
    collection do
      get 'update_communes'
      get 'data_sample_properties_excel'
      patch 'send_payment_gateways_data_to_new_portal'
    end
    resources :payment_gateway_settings, only: %i[create update]
    resources :validate_banking_settings, only: [:update]
    resources :banking_settings, only: %i[update destroy]
    resources :internal_banking_settings, only: %i[create]
  end

  resources :excel_uploads
  get 'import_data/:import_type' => 'excel_uploads#import_data', as: 'import_data'
  get 'download_template_file' => 'excel_uploads#download_template_file'
  get 'download_public_template_file' => 'excel_uploads#download_public_template_file'

  resources :property_account_statements, only: [:create] do
    collection do
      get 'preview'
    end
    member do
      get 'check_if_generated_pdf'
      post 'notify'
    end
  end

  resources :property_account_statement_settings, only: %i[edit update]

  resources :payments, only: %i[index new create show update], path: 'abonos' do
    member do
      get 'anular', as: 'nullify', action: 'nullify'
      put 'anular', as: 'raw_nullify', action: 'raw_nullify'
      get 'ocultar', as: 'hide', action: 'hide'
      get 'notificar', as: 'notify_receipt', action: 'notify_receipt'
      get 'notificar_anulado', as: 'notify_nullified', action: 'notify_nullified'
      get 'destruir_asignacion', as: 'destroy_assign_payment', action: 'destroy_assign_payment'
      get 'asignar_gasto_comun', as: 'assign_common_expense', action: 'assign_common_expense'
      get 'asignar_pagos', as: 'assign_payments', action: 'assign_payments'
      get 'set_exported'
      get 'check_if_generated_pdf'
      get 'show_modal'
      get 'regenerate_receipt'
    end
    collection do
      get 'exportar', as: 'export', action: 'export_payments_excel'
      get 'notificar_pendientes', as: 'notify_pending', action: 'notify_pending'
      get 'no_reconocidos', as: 'unrecognized', action: 'unrecognized'
      get 'no_notificados', as: 'not_notified', action: 'not_notified'
      get 'notificar_multiples', as: 'bulk_notify_receipt', action: 'bulk_notify_receipt'
      get 'dispertions', as: 'dispertions', action: 'dispertions'
      get 'mark_all_as_notified'
    end
  end

  resources :assign_payments, path: 'asignacion_de_pagos'
  resources :discounts, path: 'descuentos', except: [:show]

  resources :bundle_payments, only: %i[create update show index], path: 'abonos_masivos' do
    member do
      get 'anular', as: 'nullify', action: 'nullify'
      get 'notificar', as: 'notify_voucher', action: 'notify_voucher'
      get 'show_modal'
      get 'generate_pdf'
    end
    collection do
      get 'importar', as: 'import_data_sample', action: 'import_data_sample'
      get 'remote_voucher'
    end
  end

  resources :checkbooks, except: %i[show destroy], path: 'chequeras' do
    member do
      put 'eliminar', as: 'deactivate', action: 'deactivate'
      get 'cheques_disponibles', as: 'available_checks', action: 'available_checks'
    end
    resources :checks, only: [:index], path: 'cheques' do
      member do
        put 'liberar', as: 'set_free', action: 'set_free'
        put 'anular', as: 'nullify', action: 'nullify'
        put 'mover_cheques', as: 'move_checks', action: 'move_checks'
      end
    end
  end

  get 'debts/:id/reassign_payments' => 'debts#reassign_payments', as: :reassign_payments_debt
  resources :debts, only: %i[update create new edit destroy], path: 'deudas' do
    member do
      post 'create_interest'
      get  'surcharges'
      get  'deductions'
    end
    collection do
      get 'debt_assignation'
      get 'notify_debt_assignation'
    end
  end

  resources :deductions, only: %i[create update destroy]

  # Permissions
  resources :permissions, only: [:index], path: 'permisos' do
    collection do
      get 'user/:manager_id' => 'permissions#user', as: 'user'
      get 'community/:community_id' => 'permissions#community', as: 'community'
      get 'new_manager'
      post 'create_manager'
      get 'new_manager_partial'
      delete 'remove_manager'
      put 'update' => 'permissions', as: 'update'
      put 'update_profile' => 'permissions', as: 'update_profile'
    end
  end

  # G+ login
  get 'auth/failure', to: 'home#index'

  get 'send_defaulting_messages' => 'home#send_defaulting_messages'
  get 'admins/dashboard'
  get 'sessions/new'
  get 'log_out' => 'sessions#destroy', as: 'log_out'
  get 'log_in_form' => 'sessions#new', as: 'log_in_form'
  get 'log_in' => 'sessions#landing', as: 'log_in'
  get 'profile_selection' => 'sessions#profile_selection', as: 'profile_selection'
  get 'log_in_frame' => 'sessions#new_frame', as: 'log_in_frame'
  get 'ingresa' => 'sessions#new'
  get 'ingresa ' => 'sessions#new'
  get 'ingresa%20' => 'sessions#new'
  get 'ingresa%20.' => 'sessions#new'
  get 'activate/:token' => 'users#activate', as: 'activate'
  get 'token_renewal' => 'sessions#token_renewal', as: 'token_renewal'
  get 'resident_redirect' => 'sessions#resident_redirect' # go to residents 2.0

  # email validation
  get 'email_confirmation/:token/:community_id' => 'sessions#email_confirmation'
  post 'do_email_confirmation' => 'sessions#do_email_confirmation'

  # Recover pass
  get 'recuperar_clave' => 'sessions#recover_pass', as: 'recover_pass'
  get 'nuevo_usuario' => 'sessions#first_login', as: 'first_login'
  post 'send_new_user' => 'sessions#send_new_user', as: 'send_new_user'
  get 'recover_pass_frame' => 'sessions#recover_pass_frame', as: 'recover_pass_frame'
  post 'send_pass_recovery' => 'sessions#send_pass_recovery', as: 'send_pass_recovery'
  post 'do_change_password' => 'sessions#do_change_password', as: 'do_change_password'
  get 'new_password/:token' => 'sessions#new_password', as: 'new_password'


  # To desuscribe from contact emails
  get 'unsubscribe/:token' => 'sessions#unsubscribe', as: 'unsubscribe'
  get 'unsubscribe/:token/:from' => 'sessions#unsubscribe', as: 'unsubscribe_from'
  get 'contact' => 'home#contact', as: 'contact'

  post 'send_contact' => 'home#send_contact', as: 'send_contact'
  get 'feriados' => 'home#feriados', as: 'feriados'

  resources :sessions, only: %i[create destroy]

  resources :users, except: [:index], path: 'usuarios' do
    collection do
      get 'search_user_typeahead'
      get 'conditions'
      get 'accept_conditions'
      get 'redirect_to_hire_demo'
      post 'disable_mfa'
    end
    member do
      get 'download_identity_document_zip'
      delete 'remove_identity_documents'
      get 'users_info'
      get 'unify_bills'
      get 'properties'
      patch 'documents', action: :update_documents, as: :update_documents
      post 'validate_password'
      post 'new_existing_user'
    end
  end

  get 'invitaciones' => 'users#invitations', as: 'invitations'
  get 'invitaciones/:token' => 'users#show_invitation', as: 'show_invitation'

  # Home
  get 'home/index'
  get 'faq' => 'home#faq'
  get 'demo' => 'home#demo', as: 'demo'
  post 'complete_admin_tour' => 'home#complete_admin_tour', as: 'complete_admin_tour'
  post 'start_demo' => 'home#start_demo', as: 'start_demo'
  get 'demo_admin_data' => 'home#demo_admin_data', as: 'demo_admin_data'
  get 'mantenimiento' => 'home#server_maintenance', as: 'server_maintenance'

  get 'home' => 'home#index', as: 'home'
  get 'demo_frame' => 'home#demo_frame', as: 'demo_frame'
  get 'home/react' => 'home#react_landing'
  get 'sign_up' => 'home#sign_up'
  get 'health_check' => 'home#health_check'
  root to: 'home#landing'

  # letsencrypt
  get '/.well-known/acme-challenge/:id' => 'home#letsencrypt'

  namespace :remuneration, path: 'remuneraciones' do
    resources :salary_payments, path: 'liquidaciones' do
      member do
        get 'nullify'
        get 'document'
        get 'preview'
        patch 'upload_document'
      end
      collection do
        post 'get_indicators'
        get 'preview_modal'
      end
    end
    resources :social_credit_fees, only: %i[index create update destroy] do
      member do
        get 'fee'
      end
    end
    resources :social_credits, path: 'creditos_sociales'

    resources :finiquitos, except: %i[index destroy] do
      member do
        get 'nullify'
        get 'preview'
        get 'document'
        get 'pdf'
      end
      collection do
        get 'calculate_vacation_days'
      end
    end

    resources :salaries do
      member do
        get 'contract_file'
        patch 'update_vacation_start_date'
      end
    end

    resources :employees, path: 'empleados' do
      member do
        get 'reactive'
        get 'previred'
        get 'send_selected_salary_payments'
        put 'update_previred'
        get 'seniority_certificate'
        delete 'delete_photo'
      end
      collection do
        get 'archivo_previred' => 'employees#get_previred', as: 'get_previred'
        get 'libro' => 'employees#book', as: 'book'
        get 'regenerar_egresos' => 'employees#regenerate_service_billings', as: 'regenerate_service_billings'
        get 'statutory_declaration'
        get 'generate_statutory_declaration', defaults: { format: :xlsx }
      end
    end

    resources :vacations, path: 'vacaciones' do
      member do
        get 'destroy_documentation'
        get 'documentation'
        get 'voucher'
      end
    end

    resources :advances, path: 'avances' do
      member do
        get 'destroy_documentation'
        put 'set_not_recurrent'
        get 'documentation'
        get 'voucher'
      end
    end

    namespace :e_books do
      get 'detailed_validation'
      get 'download_lre'
      get 'validate_lre'
    end

    resources :salary_payment_drafts, path: 'libro_liquidaciones', only: %i[index update create] do
      collection do
        get 'dias_trabajados' => 'salary_payment_drafts#worked_days', as: 'worked_days'
        post 'reset'
      end
    end
  end

  # Wall
  resources :posts, path: 'publicaciones' do
    resources :assets, only: :destroy, path: 'archivos'
    member do
      get 'destroy_file'
      get 'download_pdf'
      get 'notify'
    end
    collection do
      get 'archivos' => 'posts#attachments_list', as: 'attachments'
      get 'real_estate' => 'posts#real_estate', as: 'real_estate'
      get 'no_publicadas' => 'posts#unpublished', as: 'unpublished'
      post 'asset_url'
    end
  end

  resources :post_templates, path: 'plantillas'

  resources :conferences, only: %i[show]

  # #Common Spaces y Events

  resources :common_spaces, path: 'espacios_comunes' do
    get 'get_full_slot'
    resources :events, path: 'eventos' do
      member do
        put 'confirm'
        put 'reject'
        put 'cancel'
      end
    end
    member do
      get 'search'
      patch 'toggle_availability'
    end
    collection do
      get 'available_list'
    end
  end

  resources :events, path: 'eventos', only: [:index]

  # Ingresos
  resources :incomes, path: 'ingresos' do
    member do
      get 'destroy_documentation'
      get 'destroy_receipt'
      get 'documentation'
      get 'receipt'
      post 'nullify'
    end
  end

  # Encuestas
  resources :surveys, except: [:show], path: 'votaciones' do
    resources :questions, except: %i[show edit] do
      resources :options, only: %i[index update create destroy]
      member do
        post 'add_asset'
        delete 'destroy_asset'
      end
      collection do
        get 'search'
      end
    end
    resources :answers, path: 'respuestas'
    member do
      get 'resultados', as: 'results', action: 'results'
      put 'publicar', as: 'publish', action: 'publish'
      put 'publicar_resultados', as: 'publish_results', action: 'publish_results'
      put 'close_early'
      put 'save_options_title'
      get 'ver_votaciones', as: 'show_votes', action: 'show_votes'
      delete 'draft_destroy'
    end
  end

  resources :accounts, except: %i[destroy show], path: 'cuentas' do
    collection do
      post 'confirmacion_de_pago' => 'accounts#billing_confirmation', as: 'billing_confirmation'
    end
    member do
      get 'generate_invoice_pdf'
      post 'postpone_block_date'
    end
  end

  # Facturas
  resources :invoices, only: %i[show index], path: 'facturas' do
    collection do
      get 'pagar' => 'invoices#billing', as: 'billing'
    end
    member do
      get 'pdf'
    end
  end

  resources :invoice_payments, only: [], path: 'pagos' do
    collection do
      post 'confirmacion', to: 'invoice_payments#billing_confirmation', as: 'billing_confirmation'
      get 'pendientes', to: 'invoice_payments#to_approve', as: 'to_approve'
      get 'rechazados', to: 'invoice_payments#rejected', as: 'rejected'
      get 'aprobados', to: 'invoice_payments#approved', as: 'approved'
    end
    member do
      get 'documento', to: 'invoice_payments#document', as: 'document'
      get 'recibo', to: 'invoice_payments#receipt', as: 'receipt'
    end
  end

  # installations
  resources :installations, path: 'instalaciones'

  # maintenances
  resources :maintenances, path: 'mantenciones' do
    member do
      get 'destroy_task_file'
      get 'destroy_task_file_completed'
      get 'task_file'
      get 'task_file_completed'
    end
  end

  # Inmobiliarias
  resources :community_descriptions do
    collection do
      get 'edit_all'
      put 'update_all'
    end
  end

  # Cuentas bancarias
  resources :bank_accounts, path: 'cuentas_bancarias' do
    member do
      post :select
      patch :set_default
      get :initial_transaction
    end
  end

  # Encomiendas
  resources :packages, path: 'encomiendas' do
    resources :package_collaborators, only: %i[new create]
    member do
      post 'restaurar', as: 'restore', action: 'restore'
      get 'descargar', as: 'download', action: 'download'
      post 'deshacer', as: 'undo', action: 'undo'
    end

    collection do
      get :employees
      get :property_users
      post :add_employee
      get :bulk_reception
      post :bulk_create, action: 'bulk_create', controller: 'package_collaborators'
    end
  end

  # API
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      get '/lector' => 'api#lector_version'
      post '/login' => 'users#login'
      post '/facebook_auth_data_deletion_call' => 'users#facebook_auth_data_deletion_call'
      resources :communities, only: [:index], path: 'comunidades'
      resources :logbooks, only: %i[create index update], path: 'bitacora' do
        member do
          patch 'notificar', as: 'notify', action: 'notify'
        end
      end
      resources :properties, only: [:index], path: 'propiedades'
      resources :users, only: %i[show index]
      resources :guest_registries, only: %i[create index update], path: 'visitas' do
        collection do
          get 'ultimo_registro', as: 'last_guest_registry', action: 'last_guest_registry'
        end
        member do
          get 'notificar', as: 'notify', action: 'notify'
        end
      end
    end
  end

  resources :guest_entries, only: [:destroy]
  resources :guest_registries, except: [:show], path: 'visitas' do
    collection do
      get 'autocomplete_invitation'
      get 'restore/:id', as: 'restore', action: 'restore'
      get 'notify/:id', as: 'notify', action: 'notify'
      get 'code_scanner', as: 'code_scanner', action: 'code_scanner'
      get 'check_invitation', as: 'check_invitation', action: 'check_invitation'
      get 'guests_papertrail/:version_id', as: 'guests_papertrail', action: 'guests_papertrail'
      get 'papertrail_version/:version_id', as: 'papertrail_version', action: 'papertrail_version'
    end
    member do
      post 'send_invitation'
      patch 'set_attended'
    end
  end
  resources :black_list_guests, except: [:show], path: 'visitas_no_deseadas'
  resources :logbooks, except: [:show], path: 'bitacora' do
    collection do
      get 'notificable', as: 'notifiable', action: 'notifiable'
    end
    member do
      patch 'notificar', as: 'notify', action: 'notify'
    end
  end
  resources :issues do
    resources :assets, only: :destroy
    member do
      get 'pre_close'
      put 'started', action: :set_started
      get :open_modal_accountable
      get 'archivos' => 'issues#attachments_list', as: 'attachments'
    end
    collection do
      get :closed,  defaults: { status: :closed }
      get :started, defaults: { status: :started }
      get :opened
    end
  end

  resources :time_zones do
    collection do
      get :list, action: 'list'
    end
  end

  # ADMIN
  namespace :admin do
    resources :closing_logs, only: :index do
      collection do
        get 'period_expenses'
        get 'closings'
        get 'closing_info'
      end
    end
    resources :communities, except: [:edit] do
      resources :importers, path: 'importadores', only: %i[new create]
      resources :leaving_communities, only: :new
      post 'update_committee'
      collection do
        get 'log_as_user'
      end
      member do
        post 'update_data'
        post 'update_data_after_preview'
        get 'nested_imports'
        post 'update_data_with_nested_imports'
        post 'undo_excel_upload'
        get 'select_property_excel_for_deletion'
        post 'delete_excel_uploaded_properties'
        post 'update_period'
        post 'update_admin'
        patch 'update_admin'
        patch 'update_setting'
        get 'go_forward_one_month'
        get 'go_back_one_month'
        get 'notify_all_users_about_cf'
        get 'rebuild_all_pdf'
        get 'destroy_all_interest'
        get 'reassign_overassigned_debts'
        patch 'toggle_active'
        get 'new_step2', to: 'communities#new_step2', as: 'new_step2' # account new
        post 'accounts', to: 'account#create', as: 'step2_create' # account create
        get 'change_package'
        get 'excel_statement'
        get 'update_all_business_transactions'
        get 'show_user'
        post 'clone_community'
        post 'default_password'
        get 'accounts'
        get 'accounts/new_secondary_account', to: 'accounts#new_secondary_account', as: 'new_secondary_account'
        post 'accounts/create_secondary_account', to: 'accounts#create_secondary_account', as: 'create_secondary_account'
        post 'assign_secondary_account'
        post 'deassign_secondary_account'
        patch 'update_customer_success_setting', to: 'customer_success_settings#update'
      end
    end
    resources :accounts, only: %i[index update show edit new create] do
      member do
        get 'account_state'
        get 'sincronize_with_invoices'
        get 'auto_invoice'
        get 'notify_pending'
        get 'replace'
        post 'replace', to: 'accounts#post_replace', as: 'post_replace'
      end
      collection do
        get 'show_by_rut'
        get 'new_without_community'
        post 'create_without_community'
      end
    end

    resources :user_demos, only: %i[index update] do
      member do
        post 'block'
      end
      collection do
        post 'new_registry'
        get 'send_excel'
      end
    end
    resources :data_scrapers, only: %i[index show] do
      collection do
        get 'update_value'
        get 'new_show'
        get 'new_index'
      end
      member do
        get 'show_previred'
        get 'show_sii'
      end
    end

    resources :feriados, only: %i[index new destroy create]
    resources :users, path: 'usuarios', only: %i[index show] do
      collection do
        get 'massive_import'
      end
      member do
        get 'unlock_user'
        get 'upgrade_to_superadmin'
        post 'disable_mfa'
      end
    end

    resources :superadmins do
      member do
        get 'downgrade_to_common_user'
      end
    end

    resources :period_expenses, only: %i[update index] do
      member do
        put 'alter_state'
      end
    end

    resources :invoice_payments do
      member do
        get 'validate_payment'
        get 'invalidate_payment'
        get 'document'
        get 'receipt'
      end
      collection do
        get 'generate_excel_and_send_it'
        get 'home'
        get 'index_pendings'
        get 'index_rejected'
        get 'download_template_file'
        post 'data_import_process'
        get 'pay_multiple_invoices'
        post 'post_pay_multiple_invoices'
      end
    end

    resources :invoices do
      collection do
        get 'index_to_invoice'
        get 'change_expiration_date'
        post 'post_change_expiration_date'
        post 'irs_bill'
        post 'nullify'
        post 'give_away'
        get 'generate_excel_and_send_it'
      end
      member do
        get 'cancel_irs'
        get 'irs_bill_invoice'
        get 'pdf'
        get 'notify_irs'
        get 'finkok_response_xml'
      end
    end

    resources :packages # will deprecate
    resources :base_packages, path: 'paquetes_base' do
      collection do
        get 'country_code/currency_options' => 'base_packages#get_currencies'
      end
      member do
        patch 'toggle_active'
      end
    end
    resources :package_limits, path: 'limite_paquetes'
    resources :servers, except: %i[show]


    resources :products
    resources :product_payments, only: [:index]


    get 'home' => 'home#home', as: 'home'
    post 'home/update_data' => 'home#update_data', as: 'update_data_home'
    get 'home/excel_upload' => 'home#excel_upload', as: 'excel_upload_home'
    get 'home/excel_result' => 'home#excel_result', as: 'excel_result_home'
    get 'home/ticket_support_form' => 'home#ticket_support_form', as: 'ticket_support_form'

    get 'invoke_job/:id' => 'home#invoke_job'
    get 'destroy_job/:id' => 'home#destroy_job'
    get 'destroy_all_jobs' => 'home#destroy_all_jobs'

    resources :csm_dashboards, only: [:index]
    resources :advertisements, path: 'noticias' do
      member do
        patch 'reactive'
        patch 'toggle_active'
        get 'users_clicked'
        get 'preview'
      end
    end

    resources :community_packages do
      member do
        patch 'activate'
        patch 'deactivate'
      end
    end
    # ClientUser para Administraciones
    resources :client_users, path: 'administraciones', only: %i[index update edit] do
      collection do
        get '/:user_id', action: 'show', as: 'show'
        post 'create/:user_id', action: 'create', as: 'new'
        get 'delete_relation/:user_id', action: 'delete_relation', as: 'delete_relation'
        get 'add_users/:user_id', action: 'add_users', as: 'add_users'
        post 'save_relations/:user_id', action: 'save_relations', as: 'save_relations'
        post 'add_user', action: 'add_user', as: 'add_user'
        get 'remove_user/:user_id', action: 'remove_user', as: 'remove_user'
        get 'change_happy_seal_locked/:user_id', action: 'change_happy_seal_locked', as: 'change_locked'
        get 'community_requirements/:community_id', action: 'community_requirements', as: 'community_requirements'
        get 'happy_seal_generation/:client_user_id', action: 'happy_seal_generation', as: 'happy_seal_generation'
        post 'load_communities_requirements', action: 'load_communities_requirements', as: 'load_communities_requirements'
      end
    end
    resources :supports, only: [:index]
    resources :payments_supports, only: [:index] do
      collection do
        get 'transactions'
        get 'download_payment_pdf'
        get 'gateway_information'
      end
    end

    resources :payments_stp_supports, only: [:index]
    resources :payments_stp_dispertions_supports, only: [:index]
    resources :payments_health_check_supports, only: [:index]
    resources :campaigns, only: %i[index update]
    resources :server_user_groups do
      member do
        get 'add_admins'
        post 'remove_users'
        get 'remove_admin'
      end
      collection do
        post 'add_admin'
        post '/:id', action: 'add_users'
        post ':id/remove_admin/:admin_id', action: 'remove_admin'
      end
    end

    resources :superadmin_permissions, only: %i[index destroy] do
      collection do
        get 'edit_permanent'
        get 'index_permanent'
        get 'permission_entity_options'
        get 'permission_object_options'
        patch 'update_permanent'
      end
    end

    resources :teams do
      collection do
        get 'my_index'
      end
    end
    get 'self_granted_permissions', action: 'self_granted_permissions', controller: 'superadmin_permissions'

    resources :contracts, only: %i[create update destroy show]

    resources :leaving_communities, only: %i[create index edit update] do
      member do
        patch 'cancel'
      end
    end

    resources :unbalanced_properties, only: [:index] do
      collection do
        get 'index_by_community'
        get 'repairs'
        post 'create_unbalanced_properties_report'
        patch 'run_repairs'
      end
    end
  end

  resources :outgoing_mails, only: [:index], path: 'correos' do
    collection do
      get 'correos_problematicos', as: 'index_problematic_mails', action: 'index_problematic_mails'
      get 'correos_problematicos_excel', as: 'problematic_mails_excel', action: 'problematic_mails_excel'
      get 'correos_sin_enviar', as: 'index_unsent_mails', action: 'index_unsent_mails'
      get 'list_options_users_multiselect'
      get 'list_options_properties_multiselect'
    end
    member do
      get 'ver_estados', as: 'fetch_mail_status', action: 'fetch_mail_status'
    end
  end

  resources :importers, path: 'importadores', only: %i[] do
    collection do
      post 'list_communities'
      post 'change_importer'
    end
  end

  resources :fund_movements, only: [:index]

  resources :budgets, path: 'presupuestos' do
    collection do
      get 'budget_modal_form'
      get 'year_budget_modal_form'
      post 'update_year'
    end
  end

  get 'validate_rut' => 'validations#validate_rut'
  namespace :integration, path: 'integracion' do
    resources :integrations, path: 'integracion', only: %i[edit update] do
      member do
        # put 'update_setting' => 'integration#update_setting'
      end
      collection do
        post 'importar_info', as: 'import_info', action: 'import_info'
        post 'importar_boletas', as: 'import_bills', action: 'import_bills'
      end
    end

    resources :bills, path: 'boletas', only: [:index]
  end

  # Property Users Portal
  namespace :portal do
    # get 'inicio' => 'home#home', as: 'home'
    get 'pago_facil' => 'home#easy_pay', as: 'easy_pay'
    get 'login_easy_pay' => 'home#login_easy_pay', as: 'login_easy_pay'
    get 'detalle_boleta' => 'home#bill_details', as: 'bill_details'
    get 'detalle_boletas' => 'home#ass_details', as: 'ass_details'
    get 'boletas' => 'home#bill_index', as: 'bill_index'
    get 'verify_community_online_payment' => 'home#verify_community_online_payment', as: 'verify_community_online_payment'
  end
  # Alias route for easy pay
  get 'pago_facil' => 'portal/home#easy_pay', as: 'easy_pay'
  get 'login_easy_pay' => 'portal/home#login_easy_pay', as: 'login_easy_pay'

  # PARTOWNER
  namespace :part_owner, path: 'copropietario' do
    get 'propiedad' => 'dashboard#property', as: 'property'
    get 'set_community' => 'dashboard#set_community', as: 'set_community'
  end

  resources :client_users, only: [:destroy], path: 'sello_feliz' do
    collection do
      get '/', action: 'show', as: 'show'
      post 'load_communities_requirements'
      get 'communities_requirement/:user_id/:requirement', action: 'communities_requirement', as: 'communities_requirement'
      get 'communities_requirement_repeated/:requirement', action: 'communities_requirement_repeated', as: 'communities_requirement_repeated'
      get '/:user_id/contact_me', action: 'contact_me', as: 'contact_me'
    end
  end
  resources :aliquots, path: 'distribution', only: %i[index update destroy] do
    member do
      get 'aliquot_excel'
    end
  end

  resource :normalize_transactions, only: [:update]

  resources :library_files, except: [:show], path: 'archivos_biblioteca' do
    member do
      get 'download', as: 'download'
      get 'notify_residents'
    end
  end

  post 'tour' => 'tours#create', as: 'tour_resource'
  post 'tracking_tour_event', to: 'tours#tracking_tour_event'
  post 'track_event', to: 'mixpanel#track_event'

  get 'page_under_construction' => 'application#page_under_construction'
  resources :committee_members, only: %i[create update destroy]
  namespace :reports do
    resources :income_outcome do
      member do
        get 'download_document'
        get 'download_no_email_users'
        get 'download_preview'
        get 'recipient_pdf'
        get 'send_it'
        get 'start_job'
      end
    end

    resources :anual_balance do
      member do
        get 'download_excel'
      end
    end
  end

  post 'reports/anual_balance/update_setting', to: 'reports/anual_balance#update_setting'

  get 'smart_link' => 'smart_link#index', as: 'smart_link'
  get 'checkout_login_smart_link' => 'portal_de_pagos#checkout_login_smart_link'

  resources :debit_recurrences, path: 'cargos_recurrentes' do
    member do
      post 'deactivate'
    end
  end

  namespace :collaborators do
    resources :package_employees do
      collection do
        post 'deactivate'
      end
    end
  end

  resources :companion_guests

  resources :profiles do
    collection do
      get 'edit_profile'
      get 'show_profile'
      post 'replace'
    end
  end

  namespace :async do
    defaults layout: false do
      get 'funds', to: 'no_period_dashboard#funds', as: 'no_period_dashboard_funds'
      resources :no_period_property_fines, only: [:index]
      resources :no_period_property_payments, only: [:index]
      resources :examples, only: [] do
        collection do
          get 'div_tag'
          get 'table_tag'
        end
      end
      resources :funds, only: [] do
        collection do
          get 'chart'
        end
      end
      get 'property_data', to: 'no_period_bills#property_data', as: 'no_period_bills_property_data'
    end
  end
end
