# == Schema Information
#
# Table name: communities
#
#  id                                           :integer          not null, primary key
#  accessible                                   :boolean          default(TRUE)
#  active                                       :boolean          default(TRUE)
#  active_billing                               :boolean          default(FALSE)
#  address                                      :string
#  administrator_description                    :text
#  amount_to_notify_slow_payers                 :integer          default(0)
#  auto_billing                                 :boolean          default(TRUE)
#  available_until                              :date
#  avatar                                       :string
#  avatar_updated_at                            :datetime
#  bank                                         :string
#  bcc_email                                    :string
#  bill_decimals                                :integer          default(5)
#  bill_header_1                                :string           default("LIQUIDACIÓN DE GASTOS COMUNES")
#  bill_header_2                                :string           default("AVISO DE COBRO")
#  bill_header_3                                :string           default("DETALLE DE EGRESOS GASTO COMÚN DE LA COMUNIDAD")
#  bill_header_4                                :string
#  bill_header_5                                :string           default("Egresos Comunidad")
#  bill_header_6                                :string           default("Prorrateo")
#  bill_header_7                                :string           default("Total a recolectar este mes")
#  billing_message                              :text
#  ccaf                                         :string           default("Sin CCAF")
#  certificate_number                           :integer
#  charge_notification_message                  :string
#  city                                         :string
#  comments                                     :text
#  common_price                                 :float            default(0.0)
#  community_sendgrid_key                       :string
#  company_image                                :string
#  company_image_updated_at                     :datetime
#  contact_email                                :string
#  contact_name                                 :string
#  contact_phone                                :string
#  count_csm                                    :boolean          default(TRUE)
#  country_code                                 :string           default("CL")
#  crm_email                                    :string           default("comunidadfeliz@pipedrivemail.com")
#  currency_code                                :string
#  day_of_month_to_notify_defaulty              :integer          default(15)
#  day_of_month_to_notify_unrecognized_payments :integer          default(25)
#  days_post_due_date                           :integer          default(3)
#  days_pre_due_date                            :integer          default(3)
#  defaulting_days                              :integer          default(30), not null
#  demo                                         :boolean          default(FALSE)
#  description                                  :text
#  email_text_post_due_date                     :text
#  email_text_pre_due_date                      :text
#  expiration_day                               :integer          default(22)
#  free_period_expiration_date                  :datetime
#  installation_step                            :integer          default(2)
#  isl_value                                    :float            default(0.93)
#  last_message                                 :text
#  last_sms_sent                                :date
#  mail_text                                    :text
#  mail_text_payment                            :text
#  morosity_min_amount                          :float            default(0.0)
#  morosity_months                              :integer          default(3)
#  morosity_text                                :text             default("")
#  morosity_title                               :text
#  mutual                                       :string
#  mutual_value                                 :float            default(0.0)
#  name                                         :string
#  next_bill_date                               :datetime
#  phone                                        :string
#  pricing_package                              :integer
#  prorrateo_name                               :string           default("Prorrateo")
#  remuneration_signature                       :string
#  remuneration_signature_updated_at            :datetime
#  reserve_fund_fixed                           :integer          default(0)
#  reserve_fund_initial_balance                 :integer          default(0)
#  rut                                          :string
#  setting_properties                           :boolean          default(FALSE)
#  signature                                    :string
#  signature_updated_at                         :datetime
#  slug                                         :string
#  sms_defaulting_days                          :integer          default(2)
#  sms_enabled                                  :boolean          default(TRUE)
#  sub_community_name                           :string           default("Torre")
#  sucursal_pago_mutual                         :string
#  timezone                                     :string
#  total_area                                   :float
#  total_m2                                     :float            default(0.0)
#  workers_union_rut                            :string
#  created_at                                   :datetime
#  updated_at                                   :datetime
#  account_id                                   :integer
#  balance_id                                   :integer
#  common_space_correspondent_id                :integer          default(-1)
#  comuna_id                                    :integer
#  currency_id                                  :integer          default(1)
#  interest_fund_id                             :integer
#  issues_mail_receiver_id                      :integer          default(-1)
#  op_mail_receiver_id                          :integer          default(-1)
#  pricing_id                                   :integer
#  real_estate_agency_id                        :integer
#  region_id                                    :integer
#
# Indexes
#
#  index_communities_on_comuna_id      (comuna_id)
#  index_communities_on_currency_code  (currency_code)
#  index_communities_on_region_id      (region_id)
#  index_communities_on_slug           (slug) UNIQUE
#
class Community < ApplicationRecord
  include ObjectActions::ObjectActionHelper
  include Formatter::ClassMethods
  include Countries
  include GenerateCommonExpenses
  include PeriodExpenseExtension
  include RoleExtension
  include DownloadFileTemplate
  include Preloaders::PropertyPreloaders
  include CollectionExcelGenerator
  include RutFormatter
  include Orderable
  include AttachmentTimerUpdater
  include PeriodExpensesHelper
  extend Searchable

  alias_attribute :notification_email_footer, :email_text_pre_due_date # En comunidades SC, se reutiliza esta columna para otro contexto

  has_many   :active_community_packages, -> { where(active: true) }, class_name: 'CommunityPackage', inverse_of: :community
  has_many   :active_employees, -> { where(active: true) }, class_name: 'Employee'
  has_one    :active_interest, -> { where(active: true) }, class_name: 'CommunityInterest', inverse_of: :community
  belongs_to :active_pricing, class_name: 'Pricing', foreign_key: :pricing_id, optional: true
  has_one    :administrative_address, class_name: 'Address', as: :addressable, dependent: :destroy, inverse_of: :addressable
  has_many   :administrators_community_users, -> { administrators }, class_name: 'CommunityUser'
  has_many   :aliquots, dependent: :destroy
  has_many   :all_properties, class_name: 'Property'
  has_many   :assets, -> { where(active: true) }
  has_many   :attendant_community_users, -> { where(role_code: CommunityUser.reversed_roles('Encargado'), active: true) }, class_name: 'CommunityUser'
  has_many   :available_common_spaces, -> { where(active: true, available: true) }, dependent: :destroy, class_name: 'CommonSpace'
  belongs_to :balance, inverse_of: :community, optional: true
  has_many   :bank_accounts
  has_one    :banking_setting, dependent: :destroy
  has_one    :banred_info, dependent: :destroy
  has_one    :bill_folio, -> { where(folio_type: 'Bill') }, class_name: 'Folio', dependent: :destroy
  has_many   :categories, -> { where(active: true) }, dependent: :destroy
  has_many   :collaborators
  has_many   :checkbooks, -> { where(active: true) }, dependent: :destroy
  has_many   :committee_members, -> { where(role_code: 2, active: true) }, class_name: 'CommunityUser'
  has_many   :common_expenses, -> { extending(PeriodExpenseExtension).includes(:common_expense_details, :assign_payments) }
  has_many   :common_spaces, -> { where(active: true) }, dependent: :destroy
  has_many   :community_accounts, dependent: :destroy
  has_one    :community_account_primary, -> { where(primary: true) }, class_name: 'CommunityAccount'
  has_many   :secondary_community_accounts, -> { where(primary: false) }, class_name: 'CommunityAccount'
  has_many   :community_descriptions
  has_many   :community_interests, -> { includes(:currency) }, dependent: :destroy
  has_many   :community_packages, inverse_of: :community
  has_many   :community_users, dependent: :destroy
  belongs_to :comuna, optional: true
  has_many   :contacts, dependent: :destroy
  has_one    :contract, dependent: :destroy
  belongs_to :currency, optional: true
  has_many   :debit_recurrences
  has_many   :employees, dependent: :destroy
  has_one    :enabled_users_setting, -> { merge(Setting.enabled_user_access) }, class_name: 'Setting'
  has_many   :excel_uploads, dependent: :destroy
  has_many   :fines, -> { where(active: true) }, dependent: :destroy
  has_many   :property_fine_groups, -> { where(active: true) }
  has_many   :folios
  has_many   :fund_transfers, -> { where(active: true) }, dependent: :destroy
  has_many   :funds, -> { where(active: true) }, dependent: :destroy, inverse_of: :community
  has_many   :funds_in_bill, -> { active.in_bill }, class_name: 'Fund', dependent: :destroy, inverse_of: :community
  has_many   :generated_period_expenses, -> { where(common_expense_generated: true) }, class_name: 'PeriodExpense', dependent: :destroy
  has_many   :guest_registries
  has_one    :guest_registry_folio, -> { where(folio_type: 'GuestRegistry') }, class_name: 'Folio', dependent: :destroy
  has_one    :happy_suppliers_setting
  has_many   :identifications, as: :identificable, dependent: :destroy
  has_many   :importers
  has_many   :inactive_employees, -> { where(active: false) }, class_name: 'Employee'
  has_one    :income_folio, -> { where(folio_type: 'Income') }, class_name: 'Folio', dependent: :destroy
  has_many   :installations, dependent: :destroy
  has_one    :integration, -> { where(active: true).eager_load(:integration_settings) }
  has_many   :integrations, -> { eager_load(:integration_settings) }
  has_one    :internal_banking_setting, dependent: :destroy
  has_many   :issues
  has_many   :leaving_communities
  has_one    :pending_leaving_community, -> { where(status: 0) }, class_name: 'LeavingCommunity'
  has_many   :library_files, dependent: :destroy
  has_one    :logbook_folio, -> { where(folio_type: 'Logbook') }, class_name: 'Folio', dependent: :destroy
  has_many   :logbooks
  has_many   :meters, -> { where(active: true) }, dependent: :destroy
  has_one    :mx_company
  has_many   :outgoing_mails, dependent: :destroy
  has_many   :online_payment_requests, dependent: :destroy
  has_many   :package_employees, class_name: 'Collaborators::PackageEmployee'
  has_many   :active_package_employees, -> { where(active: true) }, class_name: 'Collaborators::PackageEmployee'
  has_one    :payment_folio, -> { where(folio_type: 'Payment') }, class_name: 'Folio', dependent: :destroy
  has_many   :payment_gateway_settings
  has_one    :payment_portal_setting, -> { where(active: true) }
  has_many   :period_expenses, dependent: :destroy
  has_many   :posts, -> { where(published: true, active: true) }
  has_many   :pricings, -> { where(active: true) }, class_name: 'Pricing', foreign_key: 'package', primary_key: 'pricing_package'
  has_many   :properties, -> { where(active: true) }, dependent: :destroy, inverse_of: :community
  has_one    :property_account_statement_setting
  has_many   :property_params, -> { where(active: true) }, dependent: :destroy
  has_many   :provisions # , dependent: :destroy
  has_many   :published_surveys, -> { where(published: true, active: true).order(:published_at) }, class_name: 'Survey'
  belongs_to :real_estate_agency, optional: true
  belongs_to :region, optional: true
  has_one    :reserve_fund, -> { where(is_reserve_fund: true) }, class_name: 'Fund'
  has_many   :selected_bank_accounts, -> { where(selected: true) }, class_name: 'BankAccount'
  has_one    :service_billing_folio, -> { where(folio_type: 'ServiceBilling') }, class_name: 'Folio', dependent: :destroy
  has_many   :service_billings, dependent: :destroy
  has_many   :settings, dependent: :destroy
  has_one    :settings_user_common_spaces_access, -> { where(code: 'common_spaces', value: 2) }, class_name: 'Setting'
  has_many   :simple_common_expenses, -> { extending PeriodExpenseExtension }, class_name: 'CommonExpense'
  has_many   :suppliers, dependent: :destroy
  has_many   :surveys, -> { where(active: true).order(:published_at) }, dependent: :destroy
  has_many   :unactive_properties, -> { where(active: false) }, class_name: 'Property', dependent: :destroy
  has_many   :unavailable_common_spaces, -> { where(active: true, available: false) }, dependent: :destroy, class_name: 'CommonSpace'
  has_many   :unpublished_posts, -> { where('published = ? and active  = ?', false, true) }, class_name: 'Post'
  has_one    :visitor_setting
  has_one    :webpay_setting
  has_one    :webpay_transaction_result_folio, -> { where(folio_type: 'WebpayTransactionResult') }, class_name: 'Folio', dependent: :destroy
  has_one    :current_usage_interaction, -> { where(period: Date.current) }, class_name: 'UsageInteraction', foreign_key: :community_id
  has_many   :packages
  has_one    :payment_portal_setting
  has_one    :customer_success_setting, dependent: :destroy
  has_one    :free_debt_certificate_setting, dependent: :destroy
  has_many   :manager_and_attendant_community_users_with_bills_edit_permission, lambda {
    includes(:permissions).where(role_code: CommunityUser.reversed_roles.values_at('Administrador'), active: true)
      .or(where(role_code: CommunityUser.reversed_roles.values_at('Encargado'), active: true).includes(:permissions).where(permissions: { code: 'bills', value: 2 }))
  }, class_name: 'CommunityUser'

  # Through associations
  has_one    :account, class_name: 'Account', through: :community_account_primary
  has_many   :accounts, class_name: 'Account', through: :community_accounts
  has_many   :account_summary_sheets, through: :period_expenses, source: :account_summary_sheets, dependent: :destroy
  has_many   :active_finiquitos, -> { where(nullified: false, validated: true) }, class_name: 'Finiquito', through: :employees
  has_many   :active_salaries, -> { where(active: true) }, class_name: 'Salary', through: :active_employees
  has_many   :administrators, through: :administrators_community_users, source: :user
  has_many   :attendants, through: :attendant_community_users, source: :user
  has_many   :admins, -> { extending RoleExtension }, through: :community_users, source: :user
  has_many   :advances, through: :employees, dependent: :destroy
  has_many   :all_users, through: :all_properties
  has_many   :all_payments, through: :period_expenses, dependent: :destroy
  has_many   :all_property_fines, through: :period_expenses, dependent: :destroy
  has_many   :bills, -> { extending PeriodExpenseExtension }, through: :period_expenses, source: :bills, dependent: :destroy
  has_many   :black_list_guests, through: :properties
  has_many   :budgets, through: :period_expenses, dependent: :destroy, inverse_of: :community
  has_many   :checks, through: :checkbooks
  has_many   :community_transactions, through: :period_expenses, dependent: :destroy
  has_many   :discounts, through: :period_expenses
  has_many   :events, through: :common_spaces
  has_many   :finiquitos, through: :employees
  has_many   :future_statements, through: :properties
  has_many   :inactive_property_users, through: :properties
  has_many   :incomes, through: :period_expenses
  has_many   :invoice_lines, through: :period_expenses
  has_many   :maintenances, through: :installations, dependent: :destroy
  has_many   :managers, through: :attendant_community_users, source: :user
  has_many   :marks, -> { joins(:meter).where(meters: { active: true }).distinct }, through: :properties
  has_many   :nullified_payments, through: :period_expenses, class_name: "Payment"
  has_many   :owners, through: :properties
  has_many   :payments, through: :all_properties# , dependent: :destroy
  has_many   :properties_business_transactions, through: :properties, source: :business_transactions
  has_many   :property_account_statements, through: :properties
  has_many   :property_fines, through: :period_expenses, dependent: :destroy
  has_many   :property_user_requests, -> { where(active: true) }, through: :properties
  has_many   :property_users, through: :properties
  has_many   :salaries, through: :employees
  has_many   :secondary_accounts, class_name: 'Account', through: :secondary_community_accounts, source: :account
  has_many   :service_billing_fees, through: :service_billings, source: :fees
  has_many   :social_credits, -> { where(active: true) }, through: :employees
  has_many   :subproperties, -> { where(active: true) }, through: :properties, class_name: 'Subproperty', dependent: :destroy
  has_many   :surcharges, through: :properties
  has_many   :transfers, through: :period_expenses
  has_many   :unasigned_payments, -> { where(property_id: nil, nullified: false) }, class_name: 'Payment', through: :period_expenses, source: :payments
  has_many   :uneditable_users, ->(community) { joins(%(LEFT JOIN (SELECT DISTINCT "property_users"."user_id" FROM "property_users" INNER JOIN "properties" AS "properties" ON "properties"."id" = "property_users"."property_id" AND "properties"."community_id" <> #{community.id} AND "properties"."active" INNER JOIN "communities" ON "properties"."community_id" = "communities"."id" AND "communities"."active" WHERE "property_users"."active") AS "second_properties" ON "second_properties"."user_id" = "users"."id")).where('"second_properties"."user_id" IS NOT NULL', false).distinct }, through: :properties, source: :users
  has_many   :unpaid_debts, through: :properties
  has_many   :usage_interactions
  has_many   :debts, through: :properties
  has_many   :users, -> { where('users.active = ? ', true) }, through: :properties # TODO: uniq  porque  se  repiten los usuarios  con muchas  propiedades
  has_many   :property_user_validations, -> { where(active: true) }, through: :property_users
  has_many   :profiles
  # Dependant through associations
  has_many   :active_salary_payments, -> { where(nullified: false, validated: true) }, class_name: 'SalaryPayment', through: :active_salaries
  has_many   :invoices, through: :invoice_lines
  has_many   :salary_payments, through: :salaries
  has_many   :templates, class_name: 'PostTemplate'

  scope :accessible, -> { where(active: true, accessible: true) }
  scope :active, -> { where(active: true) }
  scope :active_and_count, -> { where(active: true, count_csm: true) }
  scope :active_and_real, -> { where(active: true, count_csm: true, demo: false) }
  scope :community_users_with_at_least_3_months, lambda {
    community_users = CommunityUser.arel_table
    joins(:community_users).where(community_users[:created_at].lteq(Date.today - 3.months))
  }
  scope :community_users_with_less_than_3_months, lambda {
    community_users = CommunityUser.arel_table
    joins(:community_users).where(community_users[:created_at].gt(Date.today - 3.months))
  }

  scope :mx_community, -> { where(country_code: 'MX') }
  scope :not_demo, -> { where(demo: false) }
  scope :stp_active, -> { joins(:settings).joins(:banking_setting).where(settings: { code: 'stp_payment_method', value: 1 }) }
  scope :stp_dispertions_active, -> { joins(:settings).joins(:banking_setting).where(settings: { code: 'stp_dispertions_payment_method', value: 1 }) }
  scope :valid_for_bulk_notifications, -> { active_and_count.accessible.not_demo }
  scope :with_period_control, -> { joins(:settings).where(settings: { code: 'period_control', value: 0 }) }
  scope :with_push_notification_users, lambda { |only_in_charge_users = false|
    query = joins(:users)
      .merge(User.with_valid_fcm_registration_token)
      .group('communities.id')
      .select('communities.id, ARRAY_AGG(DISTINCT users.id) AS push_notification_users')
    query.merge!(PropertyUser.in_charge) if only_in_charge_users

    query
  }
  scope :with_posts_created_last_days, lambda {
    accessible
      .joins(:posts, :users)
      .joins('LEFT JOIN user_read_posts ON user_read_posts.post_id = posts.id AND user_read_posts.user_id = users.id')
      .where(posts: { created_at: 15.days.ago..Time.current, active: true, published: true }, user_read_posts: { post_id: nil, user_id: nil })
      .where.not(users: { fcm_registration_token: [nil, ''] })
      .group('communities.id')
      .select('communities.id, ARRAY_AGG(DISTINCT users.id) AS users_ids')
  }
  scope :with_recently_closed_period_expense, lambda { |number_of_days|
    with_period_control
      .joins(:period_expenses).where(period_expenses: { common_expense_generated: true })
      .where('DATE(common_expense_generated_at) = ?', (Time.current - number_of_days.days).to_date)
      .distinct
  }
  scope :without_period_control, -> { joins(:settings).where(settings: { code: 'period_control', value: 1 }) }

  before_create :build_default_categories
  after_create :check_name,
               :create_balance,
               :create_folios,
               :create_online_payment_settings,
               :create_reserve_fund,
               :create_sendgrid_key,
               :set_bill_headers,
               :set_manual_assignation_value

  after_commit :request_calculate
  before_update :check_accounts
  before_save :replicate_rut
  after_update :update_period_expenses, if: :saved_change_to_expiration_day?
  before_validation -> { rut_format!(:workers_union_rut) }, if: :locale_cl?
  before_validation -> { rut_format!(:rut) }, if: :locale_cl?

  mount_uploader :avatar, AvatarUploader
  mount_uploader :company_image, AvatarUploader
  mount_uploader :signature, AvatarUploader
  mount_uploader :remuneration_signature, AvatarUploader

  validates :address, :contact_email, :morosity_months, :name, presence: true
  validates_format_of :contact_email, with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, message: 'no es válido', allow_blank: true
  validates :workers_union_rut, rut_field: true, allow_blank: true, if: :locale_cl?
  validates :rut, allow_blank: true, if: :locale_cl?, rut_field: true
  validate :isl_or_mutual
  validates :morosity_title, length: { maximum: 60 }
  validates :amount_to_notify_slow_payers, numericality: { greater_than_or_equal_to: 0 }
  validates :bill_decimals, numericality: { greater_than_or_equal_to: 3, less_than_or_equal_to: 8 }
  validates :day_of_month_to_notify_defaulty, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :days_post_due_date, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }
  validates :days_pre_due_date, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }
  validates :defaulting_days, numericality: { greater_than_or_equal_to: 0 }
  validates_presence_of :contact_name

  # Nested attributes
  accepts_nested_attributes_for :administrative_address, allow_destroy: true
  accepts_nested_attributes_for :aliquots, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :committee_members, allow_destroy: true
  accepts_nested_attributes_for :community_interests
  accepts_nested_attributes_for :contacts, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :free_debt_certificate_setting
  accepts_nested_attributes_for :funds, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :happy_suppliers_setting
  accepts_nested_attributes_for :identifications, allow_destroy: true
  accepts_nested_attributes_for :online_payment_requests
  accepts_nested_attributes_for :mx_company, reject_if: :community_not_from_mexico , allow_destroy: true
  accepts_nested_attributes_for :payment_gateway_settings
  accepts_nested_attributes_for :properties, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :property_account_statement_setting
  accepts_nested_attributes_for :service_billing_folio, :bill_folio, :payment_folio, :income_folio, :guest_registry_folio, :webpay_transaction_result_folio, :logbook_folio, reject_if: proc { |attributes| attributes['folio'].blank? }
  accepts_nested_attributes_for :visitor_setting
  accepts_nested_attributes_for :webpay_setting

  searchable_attributes :name, :address, :slug
  delegate :properties_without_email, to: :properties
  delegate :valid_expiration_date?, to: :last_closed_period_expense
  delegate :present?, to: :administrative_address, prefix: 'address', allow_nil: true

  MUTUAL = ['Sin Mutual', 'Asociación Chilena de Seguridad (ACHS)', 'Mutual de Seguridad CCHC', 'Instituto de Seguridad del Trabajo I.S.T.'].freeze
  CCAF = ['Sin CCAF', 'Los Andes', 'La Araucana', 'Los Héroes', 'Gabriela Mistral', '18 de Septiembre'].freeze

  INSTALL_STEPS = 5
  MANAGE_PERMISSION_VALUE = 3
  EDIT_PERMISSION_VALUE = 2

  DEBTS_AND_DEFAULTS_XLSX_URL = '/panel/morosidad.xlsx'.freeze
  DEFAULTING_LETTERS_PDF_URL = '/panel/cartas_morosidad.pdf'.freeze
  BILLS_PDF_URL = '/period_expenses/:period_expense_id/pdf_bills'.freeze
  BILLS_XLSX_URL = '/boletas.xlsx?month=:month&year=:year'.freeze
  COLLECTION_XLSX_URL = '/comunidades/:community_slug/collection_excel.xlsx'.freeze
  MIXED_BILLS_PDF_URL = '/period_expenses/:period_expense_id/pdf_mixed_bills'.freeze
  NOTIFY_PAYMENT_RECEIPTS_PDF_URL = '/period_expenses/:period_expense_id/notify_pdf_payment_receipts'.freeze
  PAYMENTS_XLSX_URL = '/abonos.xlsx'.freeze
  SHORT_BILLS_PDF_URL = '/period_expenses/:period_expense_id/pdf_short_bills'.freeze
  NOTIFY_EMAILS_BILSS = '/boletas/notify_emails'.freeze

  DEFAULT_FLEXIBILITY_TIME = 240

  MANUALLY_ASSIGNMENT_DEFAULT = 1
  PAYMENTS_BY_PERIOD_TIME_SCOPE = 3.months

  ONLINE_PAYMENT_AVAILABLE_COUNTRY_CODES = %w[CL MX].freeze

  def self.CCAF
    CCAF.each.map { |e| [e, e] }
  end

  def self.MUTUAL
    MUTUAL.each.map { |e| [e, e] }
  end

  #####################################
  #########    Validations    #########
  #####################################

  def isl_or_mutual
    if isl_value.to_f.positive? && mutual_value.to_f.positive?
      errors.add(:isl_value, I18n.t('messages.errors.community.isl_and_mutual_defined'))
      return false
    end
    if isl_value.to_f.zero? && mutual_value.to_f.zero?
      errors.add(:isl_value, I18n.t('messages.errors.community.isl_and_mutual_undefined'))
      return false
    end
    true
  end

  def replicate_rut
    return unless rut_before_last_save && country_code == 'CL'

    identifications.find_by(identity_type: 'RUT')&.update(identity: rut)
  end

  def phi
    webpay_setting&.phi
  end

  def delta
    webpay_setting&.delta
  end

  def commerce_code
    webpay_setting&.commerce_code
  end

  def debit_commission
    webpay_setting&.debit_commission
  end

  def credit_commission
    webpay_setting&.credit_commission
  end

  def commerce_code_oneclick
    webpay_setting&.commerce_code_oneclick
  end

  def webpay_plus_active?
    webpay_setting&.commerce_code&.present?
  end

  def oneclick_active?
    webpay_setting&.commerce_code_oneclick&.present?
  end

  def both_webpay_and_oneclick_active?
    webpay_plus_active? && oneclick_active?
  end

  def locale_cl?
    locale_to_validate = get_locale(country_code)
    locale_to_validate ||= I18n.locale.to_s
    locale_to_validate == 'es-CL'
  end

  def locale_mx?
    locale_to_validate = get_locale(country_code)
    locale_to_validate ||= I18n.locale.to_s
    locale_to_validate == 'es-MX'
  end

  def landing
    case country_code
    when 'CL'
      'www.comunidadfeliz.cl'
    when 'MX'
      'www.comunidadfeliz.mx'
    else
      'www.comunidadfeliz.com'
    end
  end

  def decimal_separator
    country_code == 'CL' ? ',' : '.'
  end

  def thousands_separator
    country_code == 'CL' ? '.' : ','
  end

  #####################################
  ######### Better Attributes ##########
  #####################################
  extend FriendlyId
  friendly_id :slug_candidates, use: %i[slugged finders]

  def slug_candidates
    [
      [:name],
      %i[name address],
      %i[name address id],
      %i[name address id created_at_slug]
    ]
  end

  def created_at_slug
    (created_at || Time.now).strftime('%m-%y')
  end

  ################################
  ######### After Update ##########
  ################################

  def check_accounts
    return unless saved_change_to_account_id? && account_id_before_last_save.present?

    throw(:abort) unless Account.find(account_id_before_last_save).check_if_empty(id)
  end

  ################################
  ######### After Create ##########
  ################################

  def set_manual_assignation_value
    get_setting('manually_assignment').update(value: MANUALLY_ASSIGNMENT_DEFAULT)
  end

  def create_balance
    balance = Balance.create(ref_class: 'communities', name: name)
    self.balance_id = balance.id
    save
  end

  def create_online_payment_settings
    activate_online_payment
  end

  def check_name
    update_attribute(:name, address) unless name
  end

  def set_bill_headers
    update_attribute(:bill_header_3, "DETALLE DE EGRESOS #{I18n.t('views.common_expenses.one').upcase} DE LA COMUNIDAD")
    update_attribute(:bill_header_4, I18n.t('views.common_expenses.one'))
  end

  def request_calculate
    # total_area common_price
    if saved_change_to_common_price?
      period_expense = get_open_period_expense
      get_open_period_expense.set_request_calculate if period_expense.present?
    end
  end

  def get_locale(locale_acron = country_code)
    case locale_acron
    when 'CL' then 'es-CL'
    when 'MX' then 'es-MX'
    when 'GT' then 'es-GT'
    when 'SV' then 'es-SV'
    when 'BO' then 'es-BO'
    when 'EC' then 'es-EC'
    when 'HN' then 'es-HN'
    when 'US' then 'en-US'
    when 'UY' then 'es-UY'
    when 'PE' then 'es-PE'
    when 'PA' then 'es-PA'
    when 'DO' then 'es-DO'
    else 'es-CL'
    end
  end

  def rut
    return read_attribute(:rut) if read_attribute(:rut).present?

    identity_type = Countries.get_identity_type(country_code)[0]
    # identity_type = get_identity_type
    identifications.detect { |i| i.identity_type == identity_type }&.identity
  end

  def get_identity_type
    locale = get_locale(country_code) if id.present?
    locale ||= I18n.locale.to_s
    case locale
    when 'es-CL' then 'RUT'
    when 'es-MX' then 'RFC'
    when 'es-GT' then 'DPI'
    when 'es-SV' then 'DUI'
    when 'es-BO' then 'NIT'
    when 'es-EC' then 'EC'
    when 'es-HN' then 'RTN'
    when 'en-US' then 'SSN'
    when 'es-UY' then 'CI'
    when 'es-PE' then 'DNI'
    when 'es-PA' then 'CIP'
    when 'es-DO' then 'CIE'
    else
      'RUT'
    end
  end

  def identity_type
    identity_type = get_identity_type
    identifications.detect { |i| i.identity_type == identity_type }&.identity_type
  end

  # Deprecated
  def set_default_mail_messages(force = false)
    middle_message = if get_setting_value('disable_users') != 0

                       " o en https://app.comunidadfeliz.cl/ingresa .
      <br> Si no recuerdas tu clave, puedes ingresar a este link https://app.comunidadfeliz.cl/recuperar_clave"
                     else
                       '.'
                     end

    if uses_period_control?
      set_period_control_mail
    else
      set_no_period_control_mail(middle_message)
    end

    # SLOW PAYER NOTIFICATIONS
    pre_slow_payer_body = I18n.t('messages.notices.communities.pre_slow_payer_notification', administrator: administrator, community: to_s)

    post_slow_payer_body = I18n.t('messages.notices.communities.post_slow_payer_notification', administrator: administrator, community: to_s)

    self.email_text_pre_due_date   = pre_slow_payer_body  + middle_message
    self.email_text_post_due_date  = post_slow_payer_body + middle_message
    self.morosity_text = I18n.t('messages.notices.communities.morosity_text')

    save if force
  end

  def set_period_control_mail
    self.mail_text = I18n.t('views.communities.bills.form.mail_text_html', community_name: name)
    self.mail_text_payment = I18n.t('views.communities.bills.form.mail_text_payment_html', community_name: name)
  end

  def set_no_period_control_mail(additional_message = '')
    self.mail_text = I18n.t('views.communities.bills.form.mail_text_no_period_html')
    self.mail_text_payment = I18n.t('messages.notices.communities.payment_body', administrator: administrator, community: to_s) + additional_message
  end

  def create_sendgrid_key
    update(community_sendgrid_key: SecureRandom.hex) unless community_sendgrid_key.present?
  end

  def update_online_payment_mail_receiver(value)
    setting = get_setting('notify_online_payment_to_admin')
    value == 1 ? setting.update(value: 1) : setting.update(value: 0)
    update(op_mail_receiver_id: -1) if op_mail_receiver_id != -1
  end

  def create_reserve_fund
    return if reserve_fund.present?

    fund = Fund.create(community_id: id, name: 'Fondo de reserva', price: 0, initial_price: 0, percentage: 0, fund_type: Fund.get_type('Porcentual'), is_reserve_fund: true)
    update_column(:interest_fund_id, fund.id) if fund.valid?
  end

  def create_folios
    folio_types = %w[Bill GuestRegistry Income Logbook Payment ServiceBilling WebpayTransactionResult]
    missing_folios = folio_types - folios.pluck(:folio_type).uniq
    return if missing_folios.blank?

    folios = []
    missing_folios.each do |folio_type|
      folios << self.folios.new(folio_type: folio_type)
    end
    Folio.import(folios)
  end

  def save_reserve_fund_by(reserve_fund_params)
    return unless reserve_fund_params.present?

    show_reserve_fund_in_service_billings = reserve_fund_params[:show_service_billings_in_bill]
    if reserve_fund_params[:reserve_fund].present?
      type = reserve_fund_params[:reserve_fund_fixed].present? ? Fund.get_type('Porcentual-Fijo') : Fund.get_type('Porcentual')
      price = reserve_fund_params[:reserve_fund_fixed].present? ? reserve_fund_params[:reserve_fund_fixed].to_f : 0
      percentage = reserve_fund_params[:reserve_fund]
      initial_price = 0
    else
      type = reserve_fund_params[:fund_type].present? ? reserve_fund_params[:fund_type] : Fund.get_type('Porcentual')
      price = reserve_fund_params[:reserve_fund_fixed].present? ? reserve_fund_params[:reserve_fund_fixed].to_f : 0
      percentage = reserve_fund_params[:percentage].present? ? reserve_fund_params[:percentage].to_f : 0
      initial_price = reserve_fund_params[:initial_price].present? ? reserve_fund_params[:initial_price].to_f : 0
    end
    fund = reserve_fund
    if fund.present?
      fund.update(price: price, percentage: percentage, fund_type: type, initial_price: initial_price, show_service_billings_in_bill: show_reserve_fund_in_service_billings)
    else
      fund = Fund.create(community_id: id, name: 'Fondo de reserva', price: price, percentage: percentage, fund_type: type, initial_price: initial_price, is_reserve_fund: true, show_service_billings_in_bill: true)
    end
    fund
  end

  #####################################
  ######### Better Attributes #########
  #####################################

  def to_s
    name
  end

  def to_i
    id
  end

  def billing_message_replace_date(stringified_date)
    modified_billing_message = billing_message
    date_placeholders = ['{FECHA_EXPIRACIÓN}', '{FECHA_EXPIRACI&Oacute;N}']
    stringified_date ||= ''
    date_placeholders.each { |date_placeholder| modified_billing_message&.gsub!(date_placeholder, stringified_date) }
    ActionController::Base.helpers.sanitize(modified_billing_message)
  end

  def full_address
    "#{address} - #{comuna}"
  end

  def get_image(size = :medium)
    return ActionController::Base.helpers.asset_path('repair_community.png') if repair?

    default_image = ActionController::Base.helpers.asset_path('edificio.png')

    begin
      avatar.present? ? avatar.expiring_url(60, size) : default_image
    rescue StandardError
      default_image
    end
  end

  def get_signature(size = :medium)
    signature.present? ? signature.expiring_url(60, size) : ''
  rescue StandardError
    ''
  end

  def get_company_image(size = :medium)
    company_image.present? ? company_image.expiring_url(60, size) : ''
  rescue StandardError
    ''
  end

  def get_remuneration_signature(size = :medium)
    has_remuneration_signature ? remuneration_signature.expiring_url(60, size) : ''
  rescue StandardError
    ''
  end

  def is_importing_data?
    Delayed::Job.where('attempts <= 1 AND (queue = ? OR community_id = ?) AND job_name = ?', "community_#{self.id}", self.id, 'DataImportJob').size.positive?
  end

  def is_creating_service_billing?
    Delayed::Job.where('community_id = ? AND job_name = ?', id, 'CreateSalaryPaymentServiceBillingJob').size.positive?
  end

  def is_notifying_payments?
    Delayed::Job.where('attempts <= 1 AND (queue = ? OR community_id = ?) AND job_name = ?', "community_#{self.id}", self.id, 'BulkNotifyPaymentsJob').size.positive?
  end

  def closing_common_expense?
    jobs = %w[ClosePeriodExpenseJob NotifyCloseJob NotifyClose2Job NotifyClose3Job
              BuildAccountSummarySheetsJob AssignBundlePaymentToAccountSummarySheetsJob BillPdfGenerationJob
              GenerateRecurrentAdvancesJob BuildAccountSummarySheetSliceJob GenerateBillPdfJob
              PushNotificationNewPaymentJob FinishAllTransfersJob CollectAllPDFJob AssGenerateSheetJob CollectAccountSummarySheetJob]
    Delayed::Job.where('attempts <= 1 AND community_id = ? AND job_name IN (?)', id, jobs).size.positive?
  end

  def has_remuneration_signature
    remuneration_signature.present?
  end

  def has_company_image?
    company_image.present?
  end

  def has_signature?
    signature.present?
  end

  def payment_portal_setting?
    payment_portal_setting.present?
  end

  def properties_population_by_meter_hash(period_expense_id:, meters_ids:)
    properties.joins(marks: :meter)
      .where(marks: { period_expense_id: period_expense_id, meters: { active: true, id: meters_ids } },
             properties: { old: false }) # TODO: Fix border case when number of old properties change between a previous period expense and the present day
      .group('marks.meter_id')
      .count('DISTINCT properties.id')
  end

  def properties_population_by_period_hash(meter_id:, period_expenses_ids:)
    properties.joins(marks: :meter)
      .where(marks: { period_expense_id: period_expenses_ids, meters: { active: true, id: meter_id } },
             properties: { old: false })
      .group('marks.period_expense_id')
      .count('DISTINCT properties.id')
  end

  def get_properties(period_expense, meter = nil, name = nil)
    properties = self.properties.joins(marks: :meter).eager_load({ property_users: :user }, :marks).where(marks: { period_expense_id: period_expense.id }, meters: { active: true }).order('marks.meter_id asc')

    properties = properties.where("(#{User.search(name.to_s)}) or (#{Property.search(name.to_s)})") if name.present?

    properties = properties.where('marks.meter_id = ?', meter) if meter.present?
    properties
  end

  def get_properties_by_params(params)
    properties = params&.defaulting_only ? self.properties.defaulting : self.properties
    properties = properties.where(id: params.ids) if params&.ids.present?
    if params&.name.present?
      properties
        .where!(
          'unaccent(lower(name)) LIKE unaccent(lower(?)) or unaccent(lower(address)) LIKE unaccent(lower(?))',
          "%#{params&.name}%",
          "%#{params&.name}%"
        )
    end

    properties.order_by_name
  end

  # retorna el period expense a utilizar en este gasto común
  def get_open_period_expense
    if get_setting_value('period_control') == 1
      current_time = TimeZone.get_local_time(date_time: DateTime.now, community: self)
      get_period_expense(current_time.month, current_time.year)
    else
      last_period_expense = last_closed_period_expense
      if last_period_expense.present?
        last_period_expense.get_next.first
      else
        # no hay gasto comun cerrado, se busca el más viejo abierto
        oldest = period_expenses.where(common_expense_generated: false).order('period asc').first
        if oldest.present?
          oldest
        else
          # Si no hay abierto se da el actual
          get_period_expense(Time.now.month, Time.now.year)
        end
      end
    end
  end

  # chequeras disponibles
  def available_checkbooks
    checkbooks.includes(:checks).select { |e| e.get_available_checks.present? }
  end

  def active_packages_to_s
    cps = active_community_packages

    total_price = cps
      .each_with_object(Hash.new(0)) { |cp, hash| hash[cp.currency_type] += cp.final_price }
      .inject('') { |cumulative_sum, (currency, sum)| "#{cumulative_sum} + #{sum} #{currency}" }
      .slice(3..-1)

    "#{cps.map(&:name).join(' - ')}: #{total_price}"
  end

  def get_community_packages_yearly_expiration
    period_active = get_open_period_expense.period
    active_community_packages.where(months_to_bill: 12, next_billing_date: period_active.strftime('%Y-%m-%d')..(period_active + 2.month).strftime('%Y-%m-%d'))
  end

  def get_possibles_pricings
    pricings
  end

  # Precio a pagar considerando comisiones de comunidad
  def calculate_commission(to_pay, commission)
    com = (-to_pay.to_f + to_pay.to_f / (1 - commission)).round
    com2 = ((to_pay / (1 - commission)).round * phi + delta).round
    result = com + com2
    result
  end

  def calculate_including_commision(to_pay, commission)
    to_pay + calculate_commission(to_pay, commission)
  end

  # Consigue el último period expense emitido
  def last_closed_period_expense
    if get_setting_value('period_control') == 1
      current_time = TimeZone.get_local_time(date_time: DateTime.now, community: self)
      return get_period_expense(current_time.month, current_time.year)
    end

    return period_expenses.sort_by(&:period).reverse!.detect(&:common_expense_generated) if association(:period_expenses).loaded?

    period_expenses.order(period: :desc).find_by(common_expense_generated: true)
  end

  # Consigue el último period expense pagado
  def last_paid_period_expense
    return period_expenses.sort_by(&:period).reverse!.detect(&:paid) if association(:period_expenses).loaded?

    period_expenses.order(period: :desc).find_by(paid: true)
  end

  # Consigue el último period expense facturado
  def last_invoiced_period_expense
    pe = if association(:period_expenses).loaded?
           period_expenses.sort_by(&:period).reverse!.detect(&:invoiced)
         else
           period_expenses.order(period: :desc).find_by(invoiced: true) # .get_next.first
         end
    return pe if pe.present?

    # en caso que no haya billing
    period = 2.month.ago.beginning_of_month
    get_period_expense(period.month, period.year)
  end

  def next_bill_date
    active_community_packages.map(&:next_billing_date).compact.min
  end

  def open_bank_reconciliations
    period_expenses.where(bank_reconciliation_closed: false)
                   .where.not(id: get_open_period_expense.id)
  end

  def last_open_bank_reconciliation
    open_bank_reconciliations.order(period: :desc).first
  end

  def last_closed_bank_reconciliation
    return period_expenses.sort_by(&:period).reverse!.detect(&:bank_reconciliation_closed) if association(:period_expenses).loaded?

    period_expenses.order(period: :desc).find_by(bank_reconciliation_closed: true)
  end

  def last_closed_not_initial_period_bank_reconciliation
    period_expenses.where(bank_reconciliation_closed: true).where.not(initial_setup: true).order('period desc').first
  end

  def last_stp_dispertion_payment
    payer_account =  banking_setting.costs_center_clabe
    company = banking_setting.costs_center_name
    DispersedPayment.where("metadata->'message'->'orden_pago'->>'empresa' = ? ", company)
                                           .where("metadata->'message'->'orden_pago'->>'cuenta_ordenante' = ? ", payer_account)
                                           .last
  end

  def first_bank_reconciliation
    period_expenses.where(first_bank_reconciliation: true).order('period desc').first
  end

  def current_bank_reconciliation
    last_closed_bank_reconciliation&.get_next&.first || period_expenses.where(first_bank_reconciliation: true).first ||
      last_open_bank_reconciliation || get_open_period_expense
  end

  def update_last_expiration_date(new_date)
    period_expense = last_closed_period_expense
    old_date = period_expense.expiration_date
    common_expenses = period_expense.common_expenses
    # TOREVIEW útil cuando cambian la fecha de gastos comunes emitidos
    debts = Debt.where(common_expense_id: common_expenses.pluck(:id))
    all_debt_ids = debts.pluck(:id).uniq

    # Pagos involucrados
    payments = Payment.where('payments.paid_at > ? and payments.property_id in (?) ', new_date, properties.pluck(:id))
    community_interest = current_interest
    debt_ids = [0]
    if old_date < new_date # POSTERGA, genera abonos por intereses facturados

      start_date = old_date.to_date

      payments.each do |p|
        p.assign_payments.each do |ap|
          debt = ap.debt
          next unless all_debt_ids.include?(debt.id) # SOLO LOS QUE CORRESPONDEN

          end_date = p.paid_at.to_date # Desde la nueva fecha hasta el día del pago
          days = (end_date - start_date).to_i
          payment = p.generate_compensation debt, community_interest, days, ap.price, "Postergar #{I18n.t('views.common_expenses.conjuntion.the.one')} #{I18n.t('views.common_expenses.one').downcase} #{days} días"

          i = debt.interests.last
          if i.present? && payment.present?
            i.description = i.description + ". Se generó una compensación de #{payment.price} por correr fecha de vencimiento de #{old_date.strftime('%d-%m-%Y')} a #{new_date.strftime('%d-%m-%Y')}"
            i.save
          end
        end
      end

    else # Retrocede, genera interes por meses vencidos
      assign_payments = AssignPayment.includes(:debt).where('paid_at > ? and payment_id in (?) ', new_date, payments.pluck(:id))
      open_period_expense = get_open_period_expense
      start_date = new_date.to_date
      assign_payments.each do |a|
        # Verificar pertinencia del interes
        debt = a.debt

        next unless all_debt_ids.include?(debt.id) # SOLO LOS QUE CORRESPONDEN

        next unless debt.interest_pertinency community_interest

        end_date = [old_date.to_date, a.paid_at.to_date].min #- 1.day # Desde la nueva fecha hasta el día del pago
        # Generar interes
        interest = a.generate_interest community_interest, open_period_expense, end_date, start_date
        # Si la fecha de facturación es menor a la actual, actualizar
        debt.update(last_interest_bill_date: end_date) if debt.last_interest_bill_date < end_date
        debt_ids << a.debt_id # actualizar la fecha en la actualización masiva

        if interest.present?
          interest.description = interest.description + ". Generado por correr fecha de vencimiento de #{old_date.strftime('%d-%m-%Y')} a #{new_date.strftime('%d-%m-%Y')}"
          interest.save
        end
      end # end each
    end

    # Actualizar Fechas
    period_expense.update_related_expiration_attrs(new_date)
    common_expenses.update_all(expiration_date: new_date)


    debts.update_all(priority_date: new_date)
    debts.where('id not in (?)', debt_ids).update_all(last_interest_bill_date: new_date)
    period_expense
  end

  def calculate_total_area
    update_attribute(:total_area, properties.sum(:size))
  end

  def get_suppliers # TODO: VER EL CASO CUANDO SE AGREGA UN NUEVO PROVEEDOR PUBLICO
    Supplier.where('public = ? or (community_id = ?)', true, id).order('name asc')
  end

  def get_categories
    Category.where('active = ? and (public = ? or community_id = ?)', true, true, id).order('categories.name ASC').order('categories.sub_name ASC')
  end

  def get_period_expense(month, year, create = true)
    candidate = period_expenses.where(period: DateTime.new(year, month)).first_or_initialize
    return candidate if candidate.persisted?

    last_closed = last_closed_period_expense unless get_setting_value('period_control') == 1
    if last_closed.present? && candidate.period < last_closed.period
      candidate.common_expense_generated = true
      candidate.common_expense_generated_at = Time.now
    end
    create ? candidate.save : candidate.set_own_expiration_date
    candidate
  end

  def get_previous_period_expense(period_expense_id)
    period_expense = period_expenses.where(id: period_expense_id).first
    if period_expense.present?
      date = period_expense.period
      date -= 1.months
      get_period_expense(date.month, date.year)
    end
  end

  def get_next_period_expenses(period_expense_id)
    period_expense = period_expenses.where(id: period_expense_id).first
    period_expenses.where('period > ?', period_expense.period).order(:period) if period_expense.present?
  end

  def get_committee_member(role_id)
    cu = community_users.where(role_code: role_id, active: true).first
    return cu.user if cu.present?

    nil
  end

  def get_manager_permissions(manager_id, permission_values = [])
    # Get community permissions by manager, and permissions access value. Empty permission_value array gets every permission
    active_community_users = community_users.where(user_id: manager_id).pluck(:id)
    if permission_values.present?
      Permission.where(community_user_id: active_community_users, value: permission_values - [0])
    else
      Permission.where(community_user_id: active_community_users).where.not(value: 0)
    end
  end

  def get_unasigned_payments
    Payment.where(period_expense_id: get_open_period_expense, property_id: nil, nullified: false).where.not(payment_type: Payment.payment_types[:webpay])
  end

  def get_proratables(by_type: false)
    if by_type
      proratables = {}
      proratables[aliquots] = aliquots if aliquots.present?
      proratables[funds] = funds if funds.present?
      proratables[meters] = meters if meters.present?
      proratables
    else
      aliquots + funds + meters
    end
  end

  def get_funds_options_for_interest
    funds.pluck(:name, :id)
  end

  def get_funds_options
    opts = [[I18n.t('views.common_expenses.one').to_s, -1]]
    opts += funds.map { |e| [e.to_s, e.id] }
    opts
  end

  def get_rounding_decimals
    Countries.get_currency_decimals(country_code, self)
  end

  def round(number)
    number.round(get_rounding_decimals)
  end

  def currency_symbol
    if currency_code
      Countries.get_currency_symbol(country_code, currency_code)
    else
      Countries.get_currency(country_code)['symbol']
    end
  end

  def currency_name
    if currency_code
      Countries.get_currency_name(country_code, currency_code)
    else
      Countries.get_currency(country_code)['name']
    end
  end

  def get_currency_code
    Countries.get_currency_code_acronym(country_code, currency_symbol)
  end

  def force_property_current_balance?
    integration.present?
  end

  def reuse_hidden_folios?
    get_setting_value(:reuse_hidden_folios).positive?
  end

  def uses_period_control?
    get_setting_value('period_control').zero?
  end

  def guest_invitation_qr_is_unique?
    get_setting_value('guest_code_validity') == 1
  end

  def can_edit_folio?
    get_setting_value('folio').positive?
  end

  def show_subproperties_in_payment_header?
    get_setting_value('show_property_in_payment_header') == 1 && !self.uses_period_control?
  end

  def enabled_common_spaces_for_residents?
    get_setting_value(:common_spaces) == 2
  end

  def happy_suppliers_setting
    super || create_happy_suppliers_setting
  end

  def property_account_statement_setting
    super || create_property_account_statement_setting
  end

  def customer_success_setting
    super || create_customer_success_setting
  end

  def free_debt_certificate_setting
    super || create_free_debt_certificate_setting(message: FreeDebtCertificateSetting::DEFAULT_MESSAGE)
  end

  ###################################
  ######### Setup Community #########
  ###################################

  def setup_email_communities(admin = nil)
    admin ||= administrator
    users.where.not(email: [nil, '']).each do |u|
      next unless u.email.count('@') == 1

      token = u.tokens.first_or_create
      NotifyFirstPasswordJob.perform_later(
        _community_id:     id,
        community_id:      id,
        admin_name:        admin.to_s,
        community_name:    to_s,
        token:             token.to_s,
        unsubscribe_token: token.value,
        user_id:           u.id,
        user_name:         u.to_s
      )
    end
  end

  def self.update_all_calculations
    Community.where(demo: false).each(&:force_update_all_calculations)
  end

  def force_update_all_calculations
    period = get_open_period_expense.period
    GeneratePeriodExpenseJob.perform_later(_community_id: id, month: period.month, year: period.year, _message: I18n.t('jobs.generate_period_expense'))
  end

  def set_to_delete_common_expenses_from_period(period_expense_id:, properties_ids: [])
    if properties_ids.empty?
      CommonExpense
        .where(period_expense_id: period_expense_id)
        .update_all(to_delete: true)

      update_query =
        CommonExpensesQueries
          .update_common_expenses_details_to_delete(
            period_expense_id: period_expense_id
          )
    else
      CommonExpense
        .where(
          period_expense_id: period_expense_id,
          property_id: properties_ids
        )
        .update_all(to_delete: true)

      update_query =
        CommonExpensesQueries
          .update_common_expenses_details_to_delete_for_properties(
            period_expense_id: period_expense_id,
            properties_ids: properties_ids
          )
    end

    ActiveRecord::Base.connection.execute(update_query)
  end

  def delete_common_expenses_from_period(period_expense)
    CommonExpenseDetail.joins(:common_expense).where('common_expenses.period_expense_id = ? AND common_expenses.to_delete = ?', period_expense.id, true).delete_all
    CommonExpense.where(period_expense_id: period_expense.id, to_delete: true).delete_all
  end

  ########################################
  ######### Dashboard Statistics #########
  ########################################

  # NO CONSIDERA abonos
  def common_expense_collected(period_expense)
    simple_common_expenses.joins(:debts).where('debts.paid = ?', true).period_expense(period_expense.id).sum(:money_paid) if period_expense
  end

  def common_expense_total(period_expense)
    simple_common_expenses.period_expense(period_expense.id).sum(:price) if period_expense
  end

  def common_expense_uncollected(period_expense)
    simple_common_expenses.joins(:debts).where('debts.paid = ?', false).period_expense(period_expense.id).sum(:money_balance) if period_expense
  end

  def common_expense_defaulting(period_expense)
    return unless period_expense

    uncollected = common_expense_uncollected(period_expense)
    collected = common_expense_collected(period_expense)
    return 0 if (collected + uncollected).zero?

    (100.0 * uncollected / (collected + uncollected)).round(2)
  end

  # del total del mes actual
  def percentage_revenue
    common_expenses = self.common_expenses.where(period_expense_id: get_open_period_expense.id)
    # TOREVIEW
    100.0 * common_expenses.joins(:debts).select('common_expenses.id').where('debts.paid = ?', true).group('common_expenses.id').count.to_f / common_expenses.count.to_f
  end
  # End methods for dashboard

  def period_outcome(period_expense)
    if period_expense.present?
      simple_common_expenses.select('sum(common_expenses.price) as ss').where(period_expense_id: period_expense.id)[0].ss
    else
      0
    end
  end

  def period_income(period_expense)
    if period_expense.present?
      simple_common_expenses.joins(:debts).select('sum(debts.money_balance) as ss').where(period_expense_id: period_expense.id)[0].ss
    else
      0
    end
  end

  def late_common_expenses_income(period_expense)
    if period_expense.present?
      common_expenses.includes(:period_expense, :debts).where('debts.paid = ? AND period_expenses.period < ?', false, period_expense.period).references(:period_expense).collect(&:money_balance).insert(0, 0).inject(:+)
    else
      0
    end
  end

  ##################################
  ######### Better Queries #########
  ##################################

  def self.search(value)
    value = value.mb_chars.unicode_normalize(:nfkd).gsub(/[^.\-x00-\x7F ]/n, '').to_s.downcase
    class_name = 'communities'
    params = %w[name address slug rut]
    query = ''
    params.each do |p|
      query += "lower(#{class_name}.#{p}) like '%#{value}%' or "
    end
    query = query[0..-4]
    query
  end

  def self.search_by_attributes(value, attributes)
    where_query = nil
    attributes.each do |param|
      arel_part = Arel::Nodes::NamedFunction.new(
        'UNACCENT', [arel_table[param].lower]
      ).matches("%#{value}%")
      where_query = where_query&.or(arel_part) || arel_part
    end
    where(where_query)
  end

  def repair?
    get_setting_value('repair_mode') == 1
  end

  def self.search_by_rut(value)
    query = Arel::Nodes::NamedFunction.new(
      'REPLACE',
      [arel_table[:rut].lower, Arel::Nodes::SqlLiteral.new("'.'"), Arel::Nodes::SqlLiteral.new("''")]
    ).matches(value.delete('.'))
    where(query)
  end

  def self.search_with_users(value: '')
    base_query = joins(:administrators)
    base_query.find_like(value, User.searchable_columns).or(
      base_query.where(id: value.to_i)
    ).or(base_query.search_by_rut(value)).order(created_at: :desc)
  end

  def get_month_payments(time)
    current_time = TimeZone.get_local_time(date_time: time, community: self)
    period_expenses_ids = self.period_expenses.pluck(:id)

    Payment
      .where(period_expense_id: period_expenses_ids)
      .where(nullified: false)
      .where("payments.paid_at <= ? AND payments.paid_at >= ?", time.end_of_month, time.beginning_of_month)
      .not_pending
  end

  ###########################
  ####### STATISTICS ########
  ###########################

  def last_closed_period_expenses # gastos comunes para un período
    simple_common_expenses.period_expense(last_closed_period_expense.id) if last_closed_period_expense
  end

  def unpaid_past_common_expenses
    simple_common_expenses.joins(:period_expense, :debts).where('debts.paid = ? AND period_expenses.period < ?', false, last_closed_period_expense.period) if last_closed_period_expense
  end

  def past_administrators
    # self.administrators.joins(:community_users).where("community_users.active = ?",false)
    community_users.includes(:user).where('community_users.active = ?', false)
  end

  ###########################
  ######### Ability #########
  ###########################

  def update_role(user, role_id)
    # Es administrador
    if role_id.to_i == CommunityUser.reversed_roles('Administrador')
      current_administrator = administrator
      if user && user != current_administrator
        # se descarta el administrador anterior
        decline_administration(current_administrator) if current_administrator.present?
        # se elimina como encargado para pasar a ser administrador
        community_users.where(user_id: user.id, role_code: CommunityUser.reversed_roles('Encargado'), active: true).first.try :set_inactive
        # se crea una nueva copia del administrador, se guarda la temporalidad de su servicio
        community_users.where(user_id: user.id, role_code: CommunityUser.reversed_roles('Administrador'), active: true).first_or_create
      end
    # Tiene un rol en la comunidad
    elsif user.present?
      # La persona actual en el cargo
      current_user_role = community_users.where('active = ? AND role_code = ?', true, role_id).first
      if current_user_role.blank? || (current_user_role.user != user)
        # Descata el rol anterior
        current_user_role.update(active: false) if current_user_role.present?
        # Entrega el nuevo rol
        user.community_users.create(community_id: id, role_code: role_id, active: true)
      end
    end

    user.update(need_to_accept_conditions: true) unless user.accepted_terms_and_conditions
  end

  def administrator
    @administrator ||= administrators.first
  end

  def decline_administration(user)
    cu = community_users.where(user_id: user.to_i, role_code: CommunityUser.reversed_roles('Administrador'), active: true).first
    cu.set_inactive if cu.present?
  end

  def can_admin?(user)
    if administrator.present?
      administrator.id == user.id || user.admin?
    else
      false
    end
  end

  def can_manage?(user)
    if managers.present?
      managers.pluck(:id).include?(user.id) || user.admin?
    else
      false
    end
  end

  ############################
  ######### Settings #########
  ############################

  def get_setting(code, cached = true)
    if cached
      s = settings.detect { |x| x.code == code.to_s }
      s.present? ? s : settings.where(code: code).first_or_create(value: Setting.default_value(code, self))
    else
      settings.where(code: code).first_or_create(value: Setting.default_value(code, self))
    end
  end

  def get_setting_value(code, cached = true)
    if cached
      s = settings.detect { |x| x.code == code.to_s }
      return s.value if s.present?

      setting = settings.where(code: code).first_or_initialize(value: Setting.default_value(code, self))
      setting.save if persisted?
      setting.value
    else
      setting = settings.where(code: code).first_or_initialize(value: Setting.default_value(code, self))
      setting.save if persisted?
      setting.value
    end
  end

  def access_control_enabled?
    get_setting_value('access_control') == 1
  end

  def auto_notify_payments?
    get_setting_value('auto_notify_payments') == 1
  end

  def online_payment_activated?
    get_setting_value('online_payment') == 1
  end

  def has_generated_period_expenses?
    generated_period_expenses.any?
  end

  def online_payment_configured_and_activate?
    webpay_setting.nil?
  end

  def activates_online_payment?
    self.period_expenses.where(closed_by_user: true).size == 1
  end

  def activate_online_payment
    if chilean?
      OnlinePayments::WebpayLegacy::CommunitiesConfigurator.new([self]).call
      OnlinePayments::Webpay::CommunitiesConfigurator.new([self]).call
    end
  end

  def activate_online_payment_setting
    online_payment_setting = Setting.find_or_create_by!(code: 'online_payment',
                                                        community_id: self.id)
    online_payment_setting.update!(value: 1)
  end

  def show_payment_online_info?
    ONLINE_PAYMENT_AVAILABLE_COUNTRY_CODES.include?(country_code)
  end

  def notify_online_payment_to_admin?
    get_setting_value('notify_online_payment_to_admin') == 1
  end

  def hide_funds_for_residents?
    get_setting_value('hide_funds') == 1
  end

  def request_identification_in_guest_registry?
    get_setting_value('require_identification_document_in_guest_registry') == 1
  end

  def show_balance_in_payment_receipt?
    get_setting_value('balance_in_payment_receipt').positive?
  end

  ############################
  ## PaymentGatewaySettings ##
  ############################

  def all_payment_gateway_settings
    all = payment_gateway_settings.to_a
    all << webpay_setting if country_code == 'CL' && webpay_setting
    all
  end

  ############################
  ######### Interest #########
  ############################

  def current_interest
    active_interest ||
      community_interests
        .where(active: true)
        .create(
          amount: 0.1,
          currency_id: Currency.find_by_name('Pesos').id,
          fixed: false,
          compound: false
        )
  end

  def update_interest(interest_params)
    interest_params['active'] = true
    current_interest.update(active: false) if current_interest.present?
    community_interests.create(CommunityInterest.whitelist(interest_params))
  end

  def update_funds(params)
    if params.present?
      params.each do |p|
        fund_param = p[1]
        if fund_param[:id].present?
          fund = funds.find_by(id: fund_param[:id])
          fund.update Fund.whitelist(fund_param)
        else
          fund = Fund.new Fund.whitelist(fund_param)
          fund.community_id = id
          fund.save if fund.name.to_s.strip.present? && fund.price.present?
        end
      end
      true
    end
  end

  def go_back_one_month
    period_expenses.order('period asc').each do |p|
      p.period = p.period - 1.month
      p.expiration_date = p.expiration_date - 1.month
      p.save
    end
  end

  def destroy_all_interest
    property_ids = properties.pluck(:id).uniq
    interests = Interest.where(property_id: property_ids)


    debt_ids = []
    # TODO: MASS UPDATE
    interests.order('end_date desc').each do |i|
      debt = i.origin_debt
      # actualizar deudas antiguas
      debt.update(last_interest_bill_date: i.start_date) if debt.present?
      # deudas a destruir (generadas por el interests)
      debt_ids << i.debt_id
      # end
    end

    # buscar pagos asignados a dichas deudas
    payment_ids = AssignPayment.where(debt_id: debt_ids).pluck(:payment_id).uniq
    assign_payments = AssignPayment.where(debt_id: debt_ids)
    debts_to_update = assign_payments.pluck(:debt_id)
    AssignPayment.where(id: assign_payments.pluck(:id)).destroy_all

    # Actualizar asginación de pagos asociados a deudas destruidas
    payments = Payment.where(id: payment_ids)
    payments.update_all({ issued: false, completed: false })
    payments.each do |p|
      p.assign_common_expense(compensation: false)
    end


    Debt.where(id: debt_ids).destroy_all
    business_transactions_ids = Interest.where(property_id: property_ids).pluck(:property_transaction_id).uniq
    Interest.where(property_id: property_ids).destroy_all

    BusinessTransaction.where(id: business_transactions_ids).each do |business_transaction|
      before_transaction = business_transaction.get_before_transaction
      business_transaction.destroy
      before_transaction.update_future
    end

    # JUST DOING AGAIN
    AssignPayment.where(id: assign_payments.pluck(:id)).destroy_all
  end

  def reassign_overassigned_debts(user = nil)
    debts = Debt.joins(:property)
                .where(properties: { community_id: id })
                .where('debts.money_balance < 0 OR debts.price - debts.money_paid <> debts.money_balance')
    unless debts.present?
      return unless user.present?

      subject = "Deudas sobreasignadas de #{self} no encontradas"
      content = '<p>No se encontraron deudas sobreasignadas</p><br><br>'
      NotifyUserAdministratorJob.perform_later(community: self, user: user, content: content, subject: subject, _message: 'Notificar administradores resultado de reasignación de deudas')
      return
    end
    property_names = properties
                     .joins(:debts)
                     .where('debts.money_balance < 0 OR debts.price - debts.money_paid <> debts.money_balance')
                     .uniq.pluck(:name)
    property_names = property_names.map { |pn| "<li>#{pn}</li>" }
    debts.each(&:reassign_payments)
    return unless user.present?

    subject = "Deudas de #{self} reasignadas"
    content = I18n.t('jobs.instanced.notify_user_administrator_content', join: property_names.join)
    NotifyUserAdministratorJob.perform_later(community: self, user: user, content: content, subject: subject, _message: 'Notificar administradores resultado de reasignación de deudas')
  end

  def update_setting(params, admin = false, current_user = nil)
    errors = []
    settings_to_update = []
    params.to_unsafe_h.each do |setting_params|
      setting = self.settings.detect { |set| set.id == setting_params[0]&.to_i }
      next if setting.only_admin_allowed_for_update(current_user)

      setting.value = setting_params[1]['value'].to_i
      settings_to_update.push(setting) if setting.has_changes_to_save?
    end

    settings_to_update.each do |setting|
      log_setting_change(setting, current_user)
      errors.push(setting.errors.messages) unless setting.save
    end

    errors.empty?
  end

  def update_setting_by_code_through_api(code, value, user)
    setting = get_setting(code)
    return unless setting && setting.api_allowed_for_update

    setting.value = value

    log_setting_change(setting, user) if setting.save!
    true
  end

  def log_setting_change(setting, current_user)
    Log.create(value: "Cambio setting: #{setting}, a #{setting.name_value}. Comunidad: #{self}",
    user_id: current_user&.id,
    community_id: self.id,
    origin_class: 'Setting',
    origin_id: setting.id)
  end

  def setup_created_properties(params, user, _excel_upload = nil)
    # Se actualiza la comunidad y se crean las propiedades.
    period_expense = last_closed_period_expense

    # Creamos el usuario Inmobiliaria para agrupar los contactos vacíos.
    if params[:real_estate_answer] == 'true'
      inmobiliaria = User.new(first_name: 'Inmobiliaria')
      inmobiliaria.generate_password
      inmobiliaria.current_attributes(community_id: id, user_id: user&.id)
      inmobiliaria.active = true
      # inmobiliaria.excel_upload = excel_upload if excel_upload.present?
      inmobiliaria.save
    end

    # Determinamos el arreglo sobre el que se iterará (dependiendo de si las propiedades están creadas o no).
    # properties = properties_create ? params[:community][:properties_attributes].values : self.properties
    properties = self.properties
    properties.each do |property|
      # Asignamos la address como el name.
      property.update(address: property.name)
      # Filtramos los parámetros para encontrar las tuplas que corresponden a la propiedad.
      params[:community][:properties_attributes].select { |_k, v| v[:name] == property.name }.each do |_, prop_params|
        next if (prop_params[:_destroy] == '1') || (prop_params[:_destroy] == 'true')

        formatted_params_expense = ActionController::Parameters.new({
                                                                      year: period_expense.period.year, month: period_expense.period.month,
                                                                      common_expense: { price: prop_params[:price].to_f }
                                                                    })
        # Se inicializan los gastos comunes con los saldos ingresados.
        CommonExpense.set_initial_setup_for_property formatted_params_expense, property, property.excel_upload unless property.common_expenses.where(period_expense_id: period_expense.id).present?

        owner_or_tenant = ((prop_params[:relationship]&.casecmp('P') == 0) || (prop_params[:relationship]&.casecmp('Propietario') == 0))
        formatted_params_user = ActionController::Parameters.new({
                                                                   user: { first_name: prop_params['co-owner'],
                                                                           email: prop_params[:mail],
                                                                           phone: prop_params[:phone] }
                                                                 })

        # Si el usuario está vacío se asocia a la Inmobiliaria (si el administrador lo eligió).
        if (params[:real_estate_answer] == 'true') && (prop_params['co-owner'].blank? && prop_params[:mail].blank? && prop_params[:phone].blank?)
          user = inmobiliaria
          prop_user = inmobiliaria.property_users.where(property_id: property.id).order('created_at desc').first_or_create(owner: true, excel_upload_id: (property.excel_upload.present? ? property.excel_upload.id : nil))
          # Sino, se inicializa el usuario y se asocia a la propiedad.
        else
          ##################################################################################
          # ##Esta funcionalidad queda fuera por ahora!!
          # Revisamos si el usuario existe en esta comunidad...
          # user_in_this_community = self.users.find_by_email(prop_params[:email].to_s.strip).present?
          # ... y si existe en otra.
          # user_in_other_community = User.where.not(id: (self.users.ids + self.administrators.ids)).where(email: prop_params[:email].to_s.strip).present?
          #
          # Creamos/modificamos y asignamos al usuario sólo si ya estaba en la comunidad o no está en otra.
          # if user_in_this_community or !user_in_other_community
          # user, prop_user = User.excel_import formatted_params_user, self, property, property.excel_upload
          # De no ser así, creamos un usuario en blanco y lo asociamos a la propiedad, incluyendo un mensaje de error respecto a eso.
          # else
          # user, prop_user = User.import_blank_user property, property.excel_upload
          # err_msg = "El mail #{prop_params[:email].to_s.strip} ya está asociado a otro usuario "
          # if property.excel_upload.error.blank?
          # property.excel_upload.error = err_msg
          # else
          # property.excel_upload.error += err_msg
          # end
          # end
          ##################################################################################

          user, prop_user = User.indep_excel_import formatted_params_user, self, property, property.excel_upload

        end

        # Hacemos el pago inicial de la propiedad cuando corresponda (luego de haber instanciado el usuario).
        property.set_initial_payment prop_params[:price].to_f, self, user if prop_params[:price].to_f < 0

        # Validamos a la persona a cargo y asignamos rol.
        if prop_user.present?
          prop_user.update(owner: owner_or_tenant)
          prop_user.save
        end
      end
    end
  end

  ##########################
  ######### FOLIOS #########
  ##########################

  def up_service_billing_folio
    service_billing_folio.up
    service_billing_folio.folio
  end

  def up_payment_folio
    payment_folio.up
    payment_folio.folio
  end

  def up_bill_folio
    bill_folio.up
    bill_folio.folio
  end

  def up_income_folio
    income_folio.up
    income_folio.folio
  end

  def up_guest_registry_folio
    guest_registry_folio.up
    guest_registry_folio.folio
  end

  def up_logbook_folio
    logbook_folio.up
    logbook_folio.folio
  end

  def up_webpay_transaction_result_folio
    webpay_transaction_result_folio.up
    webpay_transaction_result_folio.folio
  end

  ##########################
  ###### 105 Campos ########
  ##########################

  def get_codigo_mutualidad
    case mutual
    when 'Asociación Chilena de Seguridad (ACHS)'
      '01'
    when 'Mutual de Seguridad CCHC'
      '02'
    when 'Instituto de Seguridad del Trabajo I.S.T.'
      '03'
    else
      '00'
    end
  end

  def has_mutual?
    mutual != 'Sin Mutual' && mutual.present?
  end

  def self.get_ccaf_code(ccaf)
    case ccaf
    when 'Sin CCAF'
      '00'
    when 'Los Andes'
      '01'
    when 'La Araucana'
      '02'
    when 'Los Héroes'
      '03'
    when 'Gabriela Mistral'
      '03'
    when '18 de Septiembre'
      '04'
    end
  end

  ##########################
  ######### VISITORS #######
  ##########################

  def is_strict?
    visitor_setting.present? ? visitor_setting.strict_community : false
  end

  def visitor_flexibility_time
    visitor_setting.present? ? visitor_setting.flexibility_in_minutes : DEFAULT_FLEXIBILITY_TIME
  end

  ##########################
  ####### SLOW PAYERS ######
  ##########################

  def self.notify_slow_payers
    communities = []
    Community.where(active: true, demo: false).each do |community|
      if community.last_closed_period_expense.present? && community.get_setting_value('notify_slow_payer') == 1
        NotifySlowPayersJob.perform_later(_community_id: community.id, _message: I18n.t('jobs.notify_slow_payer_default', community: community))
        communities << community.to_s
      end
    end
    Log.create(value: "[SCHEDULER] Notificó atraso de Comunidades: #{communities}", origin_class: 'Community')
  end

  def notify_unpaid_debts
    I18n.locale = get_locale(country_code)

    properties_with_debt = properties.select { |p| p.unpaid_debts.length.positive? }
    properties_ids = properties_with_debt.map(&:id).uniq

    properties_current_balance = Properties::CurrentBalancesQuery.new.call(properties_ids: properties_ids)
    byebug
    properties_current_balance.select! { |_key, value| value > amount_to_notify_slow_payers }

    properties_to_notify = properties.where(id: properties_current_balance.keys).includes(:users)

    properties_last_pas_is_updated = Properties::LastPasIsUpdated.call(properties_to_notify.pluck(:id), id)

    properties_to_notify.each do |property|
      if properties_last_pas_is_updated[property.id] == true
        property.notify_users_with_unpaid_debts(properties_current_balance[property.id])
      else
        property.update_pas(options: { notify: false, notify_slow_payer: true })
      end
    end
  end

  ##########################
  ########   EXCEL   #######
  ##########################

  def self.generate_excel_import_properties(old_rows)
    file_contents = StringIO.new
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: I18n.t('excels.community.import_properties_title')


    # formating row 1
    header_format = Spreadsheet::Format.new weight: :bold, size: 10, pattern: 1, color: :white, pattern_fg_color: :green, align: :left
    7.times.each { |x| sheet.row(0).set_format(x, header_format) && sheet.column(x + 1).width = 15 }


    # COLUMNS
    # title_format = Spreadsheet::Format.new weight: :bold, size: 12
    string_format = Spreadsheet::Format.new
    string_format.number_format = '@'
    # float_format = Spreadsheet::Format.new
    # float_format.number_format = 'General'
    currency_format = Spreadsheet::Format.new
    currency_format.number_format = '[$$-340A]#,##0;[$$-340A] -#,##0'

    wrap_format = Spreadsheet::Format.new text_wrap: true

    sheet.column(0).width = 20
    sheet.column(3).width = 20
    sheet.column(6).width = 22
    sheet.column(7).width = 50

    sheet.column(2).default_format = currency_format
    sheet.column(0).default_format = string_format
    sheet.column(3).default_format = string_format
    sheet.column(4).default_format = string_format
    sheet.column(5).default_format = string_format
    sheet.column(6).default_format = string_format
    sheet.column(7).default_format = wrap_format

    sheet.row(0).insert(0, 'Departamento', 'Prorrateo', 'Saldo', I18n.t('activerecord.models.property_user.one').to_s, 'Teléfono', 'Mail', 'Arrendatario/Propietario')
    sheet[3, 7] = 'Tips'
    sheet[4, 7] = '- El departamento corresponde al nombre de la unidad.'
    sheet[5, 7] = '- El prorrateo es la alícuota o repartición de la unidad.'
    sheet[6, 7] = "- El saldo es #{I18n.t('views.property.debt.conjuntion.the.one')} #{I18n.t('views.property.debt.one').downcase} actual de la unidad."
    sheet[7, 7] = '- No agregues campos nuevos al excel, estos no se incluirán.'
    sheet[8, 7] = "- Para ingresar múltiples #{I18n.t('activerecord.models.property_user.other').downcase} en una misma unidad, copia la fila y modifica los datos del usuario."
    old_rows.each_with_index do |data, index|
      sheet.row(index + 1).insert(data[0], data[1], data[2], data[3], data[4], data[5], data[6])
    end

    book.write file_contents

    file_contents
  end

  def self.get_properties_excel_length(excel_upload)
    spreadsheet = excel_upload.open_spreadsheet
    if spreadsheet
      (2..spreadsheet.last_row).size
    else
      { errors: 'No se pudo abrir el Excel.', row_counter: 0 }
    end
  end

  def self.excel_preimport_N_properties(excel_upload, n)
    spreadsheet = excel_upload.open_spreadsheet
    if spreadsheet # se pudo abrir el excel
      rows = []
      # has_id=spreadsheet.row(1).include? "ID"
      # puts spreadsheet.row(0).to_s
      # puts spreadsheet.row(1).to_s
      row_counter = 0
      records = []
      errors = []
      (2..n).each do |number|
        row_counter += 1
        puts row_counter
        params = excel_upload.parse_params(spreadsheet.row(number), spreadsheet.row(1))

        rows << params
        # Importante: el parser se marea un poco cuando tiene campos adicionales (como los comentarios que escribí)
        # No se cae, pero agrega líneas en blanco. Debería evitar esto o no importa?

        # puts "params! #{params.to_s}"
        # puts spreadsheet.row(number).to_s
        # Ordenador de importadores a usar
        obj_errors = excel_upload.importer params, records
        obj_errors = obj_errors.prepend("Fila: #{row_counter}") unless obj_errors.empty?
        errors += obj_errors
      end

      unless errors.present? && !errors.empty? && errors[0].present?
        excel_upload.imported = true
        excel_upload.save
      end

      rows
    else
      { errors: 'No se pudo abrir el Excel.', row_counter: 0 }
    end
  end

  def self.excel_preimport_properties(excel_upload)
    spreadsheet = excel_upload.open_spreadsheet
    if spreadsheet # se pudo abrir el excel
      excel_preimport_N_properties excel_upload, spreadsheet.last_row
    else
      { errors: 'No se pudo abrir el Excel.', row_counter: 0 }
    end
  end

  def excel_direct_import_properties(excel_upload, user)
    spreadsheet = excel_upload.open_spreadsheet
    if spreadsheet
      properties = []
      property_names = Set.new
      row_counter = 0
      errors = []
      excel_params = []

      (2..spreadsheet.last_row).each do |number|
        row_counter += 1
        puts row_counter
        params = excel_upload.parse_params(spreadsheet.row(number), spreadsheet.row(1))
        excel_params << params

        params[:departamento] = params[:departamento].to_s.strip if params[:departamento].to_s.strip != ''
        params[:prorrateo] = params[:prorrateo].to_f if params[:prorrateo].to_s.strip != ''

        next unless params[:departamento].present?

        property = Property.new(name: params[:departamento], size: params[:prorrateo], community: self, excel_upload_id: excel_upload.id)


        if property.valid? excel_upload
          unless property_names.include? property.name
            properties << property
            property_names << property.name
          end
        else
          obj_errors = property.errors.full_messages.join('<br>').to_s
          obj_errors = obj_errors.prepend("Fila: #{row_counter}")
          errors << obj_errors
          return errors
        end
      end

      # Si no hay errores, crea las propiedades.
      unless errors.present?
        a = Property.import properties.to_a
        properties.each do |prop|
          # Sólo :save? O también :before?
          prop.run_callbacks(:create)
          prop.run_callbacks(:save)
        end

        # Por último, hacemos el setup asociado a las propiedades.
        formatted_params = Community.properties_attributes_format(excel_params)
        setup_created_properties formatted_params, user

      end
    else
      { errors: 'No se pudo abrir el Excel.', row_counter: 0 }
    end
  end

  def update_all_property_balance
    Balance.where(id: properties.pluck(:balance_id)).each do |b|
      if b.present?
        bt = b.business_transactions.order('created_at asc').first
        bt.update_future if bt.present?
      end
    end
  end

  ####################################
  ##########  Excel Helper  ##########
  ####################################

  def self.properties_attributes_format(params)
    # Inicializamos hash.
    property_params = { community: { properties_attributes: {} } }
    counter = 1

    params.each do |row|
      prop_hash = {
        name:         (row['departamento']).to_s,
        size:         (row['prorrateo']).to_s,
        price:        (row['saldo']).to_s,
        'co-owner' => (row[I18.t('activerecord.models.property_user.one').downcase]).to_s,
        phone:        (row['teléfono']).to_s,
        mail:         (row['mail']).to_s,
        relationship: (row['arrendatario/propietario']).to_s,
        _destroy:     'false'
      }
      property_params[:community][:properties_attributes][counter.to_s] = prop_hash
      counter += 1
    end
    property_params
  end

  # keep_period_expense: true
  # keep_bills: true
  # keep_invoice: true
  # keep_properties: true
  # keep_fines: true
  # keep_meter: true
  # keep_marks: true
  # keep_remuneration: true
  # keep_guest: true

  # args = {} ; args[:keep_period_expense] = args[:keep_bills]= args[:keep_invoice]= args[:keep_properties]= args[:keep_fines]= args[:keep_meter]= args[:keep_marks]= args[:keep_remuneration]= args[:keep_guest]=true
  # Community.find(1).duplicate_community keep_meter: true , keep_remuneration: true

  ##########################
  ####### DUPLICATE ########
  ##########################

  def duplicate_community(args = {})
    keep_period_expense = args[:keep_period_expense].present? ? args[:keep_period_expense] : false
    keep_bills          = args[:keep_bills].present? ? args[:keep_bills] : false
    keep_invoice        = args[:keep_invoice].present? ? args[:keep_invoice] : false
    keep_properties     = args[:keep_properties].present? ? args[:keep_properties] : false
    keep_fines          = args[:keep_fines].present? ? args[:keep_fines] : false
    keep_meter          = args[:keep_meter].present? ? args[:keep_meter] : false
    keep_marks          = args[:keep_marks].present? ? args[:keep_marks] : false
    keep_remuneration   = args[:keep_remuneration].present? ? args[:keep_remuneration] : false
    keep_guest          = args[:keep_guest].present? ? args[:keep_guest] : false


    id_map = {}
    id_map[:properties] = {}
    id_map[:aliquots] = {}
    id_map[:fines] = {}
    id_map[:bills] = {}
    id_map[:funds] = {}
    id_map[:finiquitos] = {}
    id_map[:incomes] = {}
    id_map[:interests] = {}
    id_map[:marks] = {}
    id_map[:property_fines] = {}
    id_map[:provision_period_expenses] = {}
    id_map[:salary_payments] = {}
    id_map[:service_billings] = {}
    id_map[:period_expenses] = {}

    new_community = nil
    origin = self
    ActiveRecord::Base.transaction do
      new_community = origin.dup
      new_community.name = new_community.name + ' (copy)'
      new_community.save

      new_community = Community.find(new_community.id)

      # settings
      origin.settings.each { |e| new_community.settings << e.dup }
      # Fondos
      origin.funds.each do |old_fund|
        new_fund = old_fund.dup
        new_fund.community_id = new_community.id
        new_fund.save
        id_map[:funds][old_fund.id] = new_fund.id
      end


      # categories
      origin.categories.each { |e| new_community.categories << e.dup }

      # community_descriptions
      origin.community_descriptions.each { |e| new_community.community_descriptions << e.dup }

      # suppliers
      origin.suppliers.each do |e|
        supplier            = e.dup
        supplier.balance_id = nil
        supplier.community_id = new_community.id
        supplier.save
      end

      new_community.save

      # Intereses
      id_map[:community_interests] = {}
      origin.community_interests.each do |e|
        new_community_interests = e.dup
        new_community_interests.community_id = new_community.id
        new_community_interests.save
        id_map[:community_interests][e.id] = new_community_interests.id
      end


      if keep_properties
        # aliquots
        origin.aliquots.each do |e|
          aliquot = e.dup
          aliquot.community_id = new_community.id
          aliquot.save
          id_map[:aliquots][e.id] = aliquot.id
        end
        new_community.save
        # Propiedades , subproperties,
        origin.properties.each do |e|
          property = e.dup
          property.reference_id = e.id
          e.subproperties.each { |s| property.subproperties << s.dup }
          property.community_id = new_community.id
          property.excel_upload_id = nil
          property.save
          e.property_aliquots.each do |pa|
            property_aliquot = pa.dup
            property_aliquot.aliquot_id = id_map[:aliquots][e.id]
            property_aliquot.property_id = property.id
          end
          id_map[:properties][e.id] = property.id
        end
      end
      new_community.save
    end # end ActiveRecord::Base.transaction

    # Property users
    return false unless new_community.id.present?

    # Periodos
    if keep_period_expense
      origin.period_expenses.each do |old_period_expense|
        new_period_expense = old_period_expense.dup
        new_period_expense.community_id = new_community.id
        new_period_expense.pdf_bills = old_period_expense.pdf_bills
        new_period_expense.pdf_salary_payments = old_period_expense.pdf_salary_payments
        new_period_expense.pdf_advances = old_period_expense.pdf_advances
        new_period_expense.pdf_short_bills = old_period_expense.pdf_short_bills
        new_period_expense.pdf_grouped_bills = old_period_expense.pdf_grouped_bills
        new_period_expense.common_expense_generated = false
        new_period_expense.save
        id_map[:period_expenses][old_period_expense.id] = new_period_expense.id
      end
    else
      origin.period_expenses.each do |e|
        new_period_expense = new_community.get_period_expense(e.period.month, e.period.year)
        id_map[:period_expenses][old_period_expense.id] = new_period_expense.id
      end
    end
    new_community.save

    if keep_fines
      # fines
      origin.fines.each do |old_fine|
        new_fine = old_fine.dup
        new_fine.community_id = new_community.community_id
        new_fine.save
        id_map[:fines][old_fine.id] = new_fine.id
      end

      if keep_properties
        # Multas
        origin.property_fines.each do |e|
          new_property_fine = e.dup
          # get periodo
          new_period = new_community.get_period_expense(e.period_expense.period.month, e.period_expense.period.year)

          new_property_fine.fine_id           = id_map[:fines][e.fine_id] if e.fine.present?
          new_property_fine.property_id       = id_map[:properties][e.property_id] if e.property_id.present?
          new_property_fine.period_expense_id = new_period.id
          new_property_fine.excel_upload_id   = nil
          new_property_fine.community_id      = new_community.id
          new_property_fine.issued            = false
          new_property_fine.save
          # new_community.property_fines << new_property_fine
          id_map[:property_fines][e.id] = new_property_fine.id
        end
      end

    end

    if keep_meter

      # meters
      origin.meters.each do |old_meter|
        new_meter = old_meter.dup
        new_meter.community_id = new_community.id
        new_meter.save
        next unless keep_properties && keep_marks

        old_meter.marks.each do |old_mark|
          new_mark              = old_mark.dup
          new_mark.meter_id     = new_meter.id
          new_mark.property_id  = id_map[:properties][old_mark.property_id] if old_mark.property.present?
          new_mark.save
          id_map[:marks][old_mark.id] = new_mark.id
        end
      end
    end


    # posts
    origin.posts.each do |e|
      new_posts = e.dup
      new_posts.community_id = new_community.id
      new_posts.file = e.file
      new_posts.send_by_email = false # marcar como falso para que no envíe correos
      new_posts.save
      e.assets.each do |old_asset|
        new_asset = old_asset.dup
        new_asset.document = old_asset.document
        new_asset.documentable_id = new_posts.id
        new_asset.save
      end
      # volver a actualizar para que mantenga data
      new_posts.update send_by_email: e.send_by_email
    end


    new_community.save

    # installations
    origin.installations.each do |e|
      installation = e.dup
      e.maintenances.each do |m|
        maintenance = m.dup
        maintenance.task_file = m.task_file
        maintenance.task_file_completed = m.task_file_completed
        if m.supplier.present?
          supplier = new_community.suppliers.where(name: m.supplier.name).first
          maintenance.supplier_id = supplier.id if supplier.present?
        end
        installation.maintenances << maintenance
      end

      new_community.installations << installation
    end
    new_community.save


    if keep_guest
      # guest_registries
      origin.guest_registries.each do |e|
        # get property
        new_guest = e.dup
        if keep_properties
          new_guest.property_id =  id_map[:properties][e.property_id] if e.property.present?
        else
          new_guest.property_id = nil
          new_guest.name        = new_guest.name + " (#{e.property.name})"
        end
        # copiar archivo si está presente
        if e.asset.present?
          asset = e.asset.dup
          asset.document = e.asset.document
          new_guest.asset = asset
        end
        new_community.guest_registries << new_guest
      end
    end

    new_community.save

    new_community = Community.find(new_community.id)

    # Egresos
    id_map[:service_billings] = {}
    origin.service_billings.each do |e|
      new_service_billing = e.dup
      # get category
      category            = new_community.categories.where(name: e.category.name).first
      # get supplier
      supplier            = new_community.suppliers.where(name: e.supplier.name).first
      # get periodo
      period_expense      = new_community.get_period_expense e.period_expense.period.month, e.period_expense.period.year

      if keep_properties
        # get aliquot
        aliquot = new_community.aliquots.where(name: e.aliquot.name).first if e.aliquot.present?
      end

      # fund
      fund = new_community.funds.where(name: e.fund.name).first if e.fund.present?


      new_service_billing.category_id          = category.id          if category.present?
      new_service_billing.supplier_id          = supplier.id          if supplier.present?
      new_service_billing.period_expense_id    = period_expense.id    if period_expense.present?
      new_service_billing.aliquot_id           = aliquot.id           if keep_properties && aliquot.present?
      new_service_billing.excel_upload_id      = nil
      new_service_billing.previous_supplier_id = nil
      new_service_billing.fund_id              = fund.id if fund.present?
      new_service_billing.community_id         = new_community.id
      new_service_billing.receipt = e.receipt
      new_service_billing.bill = e.bill
      new_service_billing.save

      id_map[:service_billings][e.id] = new_service_billing.id

      e.assets.each do |old_asset|
        new_asset = old_asset.dup
        new_asset.document = old_asset.document
        new_asset.documentable_id = new_service_billing.id
        new_asset.save
      end

      next unless keep_meter

      e.service_billing_meters.each do |sbm|
        meter = new_community.meters.where(name: sbm.meter.name).first
        next unless meter.present?

        new_service_billing_meter = sbm.dup
        new_service_billing_meter.meter_id           = meter.id
        new_service_billing_meter.service_billing_id = new_service_billing.id
        new_service_billing_meter.save
      end
    end


    # provisions

    # Ingresos Extraordinarios

    # incomes
    # id_map[:incomes][old_income.id ] = new_income.id

    # common_spaces

    # common_spaces
    # events

    if keep_remuneration
      # Remuneraciones
      origin.employees.each do |e|
        employee = e.dup
        employee.community_id = new_community.id
        employee.photo = e.photo
        employee.save

        e.salaries.each do |salary|
          new_salary = salary.dup
          new_salary.employee_id = employee.id
          new_salary.contract_file = salary.contract_file
          new_salary.save
          salary.salary_payments.each do |salary_payment|
            new_salary_payment = salary_payment.dup
            new_salary_payment.salary_id = new_salary.id
            new_salary_payment.service_billing_id = id_map[:service_billings][salary_payment.service_billing_id] if salary_payment.service_billing.present?
            #  period_expense_id
            period_expense = new_community.get_period_expense salary_payment.period_expense.period.month, salary_payment.period_expense.period.year
            new_salary_payment.period_expense_id = period_expense.id

            #  payment_period_expense_id
            payment_period_expense = new_community.get_period_expense salary_payment.payment_period_expense.period.month, salary_payment.payment_period_expense.period.year
            new_salary_payment.payment_period_expense_id = payment_period_expense.id

            if keep_properties && salary_payment.service_billing.present?
              #  aliquot_id
              sb = ServiceBilling.where(new_salary_payment.service_billing_id).first
              new_salary_payment.aliquot_id = sb.aliquot_id if sb.present?
            end

            # copiar archivos
            new_salary_payment.document = salary_payment.document
            new_salary_payment.pdf = salary_payment.pdf
            new_salary_payment.save
            id_map[:salary_payments][salary_payment.id] = new_salary_payment.id
          end
        end

        # refresh relations
        employee = Employee.find(employee.id)

        e.finiquitos.each do |f|
          # copiar archivos
          finiquito                    = f.dup
          finiquito.employee_id        = employee.id
          finiquito.salary_id          = employee.active_salary.id
          finiquito.service_billing_id = id_map[:service_billings][f.service_billing_id] if f.service_billing.present?
          finiquito.document        = f.document
          finiquito.pdf             = f.pdf

          period_expense = new_community.get_period_expense f.period_expense.period.month, f.period_expense.period.year
          finiquito.period_expense_id = period_expense.id

          if keep_properties
            #  aliquot_id
            finiquito.aliquot_id = id_map[:aliquots][f.aliquot_id] # new_community.aliquots.where(name: f.aliquot.name).first.id if f.aliquot.present?
          end
          #  service_billing_id   -> No podemos manejarlo por el momento
          finiquito.save

          id_map[:finiquitos][f.id] = finiquito.id
        end

        e.advances.each do |advance|
          new_advance                              = advance.dup
          new_advance.employee_id                  = employee.id
          new_advance.service_billing_id           = id_map[:service_billings][advance.service_billing_id] if advance.service_billing.present?
          new_advance.auto_create_service_billing  = false
          new_advance.documentation = advance.documentation
          new_advance.voucher = advance.voucher

          period_expense = new_community.get_period_expense advance.period_expense.period.month, advance.period_expense.period.year
          new_advance.period_expense_id = period_expense.id

          new_advance.save
        end
        # e.social_credits.each do |f|

        # end
      end
    end


    # Invoces
    if keep_invoice
      # invoice_lines
      # invoices
    end

    # transfers

    # stage 2
    if keep_properties
      new_community = Community.find new_community.id
      new_community.copy_properties_from origin, id_map

      origin.property_users.each do |old_property_user|
        new_property_user = old_property_user.dup
        new_property_user.property_id = id_map[:properties][old_property_user.property_id]
        new_property_user.save
      end
    end

    if keep_period_expense
      origin.period_expenses.each do |e|
        new_community.get_period_expense(e.period.month, e.period.year).update(initial_setup: e.initial_setup, bank_reconciliation_closed: e.bank_reconciliation_closed, common_expense_generated: e.common_expense_generated, common_expense_generated_at: e.common_expense_generated_at)
      end
      new_community.property_fines.where(period_expense_id: new_community.period_expenses.where(common_expense_generated: true).pluck(:id)).update_all issued: true
    end
  end

  def copy_properties_from(origin, id_map)
    id_map[:debts] = {}
    id_map[:business_transactions] = {}
    id_map[:common_expenses] = {}

    properties.each do |new_property|
      old_property = origin.properties.find new_property.reference_id

      new_balance = new_property.balance
      unless new_balance.present?
        new_balance = old_property.balance.dup
        new_balance.save
        new_property.balance_id = new_balance.id
        new_property.save
      end

      old_property.debts.each do |old_debt|
        new_debt = old_debt.dup
        new_debt.property_id = new_property.id
        new_debt.reference_id = old_debt.id
        new_debt.save
        id_map[:debts][old_debt.id] = new_debt.id
      end

      old_property.balance.business_transactions.each do |old_business_transaction|
        new_business_transaction = old_business_transaction.dup
        new_business_transaction.balance_id = new_balance.id
        new_business_transaction.reference_id = old_business_transaction.id
        # actualizar origin_id si es debt
        new_business_transaction.origin_id = id_map[:debts][old_business_transaction.origin_id] if new_business_transaction.origin_type == 'Debt'
        new_business_transaction.save

        id_map[:business_transactions][old_business_transaction.id] = new_business_transaction.id
      end


      old_property.common_expenses.each do |old_common_expense|
        # get periodo
        new_period = get_period_expense old_common_expense.period_expense.period.month, old_common_expense.period_expense.period.year

        new_common_expense = old_common_expense.dup
        new_common_expense.property_id = new_property.id
        new_common_expense.community_id = new_property.community_id
        new_common_expense.period_expense_id = new_period.id
        new_common_expense.property_transaction_id = id_map[:business_transactions][old_common_expense.property_transaction_id] if old_common_expense.property_transaction_id.present?
        new_common_expense.debt_id = Debt.find_by_reference_id(new_common_expense.debt_id).id if new_common_expense.debt_id.present?
        new_common_expense.reference_id = old_common_expense.id
        new_common_expense.excel_upload_id = nil
        new_common_expense.community_interest_id = id_map[:community_interests][old_common_expense.community_interest_id] if old_common_expense.community_interest_id.present?
        new_common_expense.save
        id_map[:common_expenses][old_common_expense.id] = new_common_expense.id
        # actualiar origin
        new_common_expense.property_transaction.update(origin_id: new_common_expense.id) if new_common_expense.property_transaction.present?
      end
      old_property.debts.each do |old_debt|
        new_debt = Debt.find(id_map[:debts][old_debt.id])
        new_debt.common_expense_id = id_map[:common_expenses][old_debt.common_expense_id] if old_debt.common_expense_id.present?
        new_debt.save
      end

      payment_ids = {}
      old_property.payments.each do |old_payment|
        # get periodo
        new_period = get_period_expense old_payment.period_expense.period.month, old_payment.period_expense.period.year

        new_payment = old_payment.dup
        new_payment.property_id = new_property.id
        new_payment.period_expense_id = new_period.id
        new_payment.property_transaction_id = id_map[:business_transactions][old_payment.property_transaction_id] if old_payment.property_transaction_id.present?
        new_payment.nullified_transaction_id = id_map[:business_transactions][old_payment.nullified_transaction_id] if old_payment.nullified_transaction_id.present?
        new_payment.receipt = old_payment.receipt
        new_payment.excel_upload_id = nil
        new_payment.completed = true # al final se vuelve a acutalizar para que se asine solo
        new_payment.reference_id = old_payment.id

        #  bundle_payment_id        :integer  - Despues revisar

        # old_payment.compensation_payments

        new_payment.save

        new_payment.property_transaction.update(origin_id: new_payment.id) if new_payment.property_transaction.present?
        new_payment.nullified_transaction.update(origin_id: new_payment.id) if new_payment.nullified_transaction.present?

        payment_ids[old_payment.id] = new_payment.id

        # Quizás se asignan solos :D
        old_payment.assign_payments.each do |old_assign_payment|
          new_assign_payment = old_assign_payment.dup
          new_assign_payment.payment_id = new_payment.id
          new_assign_payment.debt_id = id_map[:debts][old_assign_payment.debt_id]
          new_assign_payment.save
        end
        new_payment.update completed: old_payment.completed
      end

      #  actualiar pagos originados por origin_payment_id
      old_property.payments.where.not(origin_payment_id: nil).each do |old_payment|
        new_payment = Payment.find(payment_ids[old_payment.id])
        new_payment.update origin_payment_id: payment_ids[new_payment.origin_payment_id]
      end


      old_property.bills.each do |old_bill|
        # get periodo
        new_period = get_period_expense old_bill.period_expense.period.month, old_bill.period_expense.period.year

        new_bill = old_bill.dup
        new_bill.property_id = new_property.id
        new_bill.period_expense_id = new_period.id
        new_bill.active_common_expense_id = CommonExpense.find_by_reference_id(old_bill.active_common_expense_id).id if old_bill.active_common_expense_id.present?
        new_bill.bill = old_bill.bill
        new_bill.bar_code = nil
        new_bill.construct_bill_number
        new_bill.save

        id_map[:bills][old_bill.id] = new_bill.id

        CommonExpense.where(reference_id: old_bill.common_expenses.pluck(:id)).update_all(bill_id: new_bill.id)
        # Payment.where(reference_id: old_bill.payments.pluck(:id) ).update_all( bill_id: new_bill.id)

        ids = []
        old_bill.payments.pluck(:id).each do |id|
          ids << payment_ids[id]
        end
        Payment.where(id: ids).update_all(bill_id: new_bill.id)
      end

      old_property.interests.each do |old_interest|
        period = get_period_expense old_interest.period_expense.period.month, old_interest.period_expense.period.year
        new_interest = old_interest.dup
        new_interest.property_id = new_property.id
        new_interest.community_interest_id   =  id_map[:community_interests][old_interest.community_interest_id] if old_interest.community_interest_id.present?
        new_interest.origin_debt_id          =  id_map[:debts][old_interest.origin_debt_id] if old_interest.origin_debt_id.present?
        new_interest.period_expense_id       =  period.id
        new_interest.debt_id                 =  id_map[:debts][old_interest.debt_id] if old_interest.debt_id.present?
        new_interest.property_transaction_id =  id_map[:business_transactions][old_interest.property_transaction_id] if old_interest.property_transaction_id.present?
        new_interest.common_expense_id       =  id_map[:common_expenses][old_interest.common_expense_id] if old_interest.common_expense_id.present?
        new_interest.excel_upload_id         = nil
        new_interest.save
        new_interest.property_transaction.update(origin_id: new_interest.id) if new_interest.property_transaction.present?

        id_map[:interests][old_interest.id] = new_interest.id
      end


      # CommonExpenseDetails

      # BillDetails

      BillDetail.where(bill_id: old_property.bills.pluck(:id)).each do |old_bill_detail|
        new_bill_detail = old_bill_detail.dup
        new_bill_detail.bill_id = id_map[:bills][old_bill_detail.bill_id]
        new_bill_detail.aliquot_id = id_map[:aliquots][old_bill_detail.aliquot_id]
        case new_bill_detail.ref_object_class
          # when "AssignPayment" Cagamos, esto no se como asignarlo facilmente si se genera automáticamente
        when 'Bill'
          new_bill_detail.ref_object_id = id_map[:bills][old_bill_detail.ref_object_id]
        when 'Community'
          new_bill_detail.ref_object_id = if old_bill_detail.description == 'CustomFund'
                                            id_map[:funds][old_bill_detail.ref_object_id]
                                          else
                                            new_community.id
                                          end
        when 'Finiquito'
          new_bill_detail.ref_object_id = id_map[:finiquitos][old_bill_detail.ref_object_id]
          # when "Income"
          #   new_bill_detail.ref_object_id = id_map[:incomes][old_bill_detail.ref_object_id]
        when 'Interest'
          new_bill_detail.ref_object_id = id_map[:interests][old_bill_detail.ref_object_id]
        when 'Mark'
          new_bill_detail.ref_object_id = id_map[:marks][old_bill_detail.ref_object_id]
        when 'PropertyFine'
          new_bill_detail.ref_object_id = id_map[:property_fines][old_bill_detail.ref_object_id]
        when 'ProvisionPeriodExpense'
          new_bill_detail.ref_object_id = id_map[:provision_period_expenses][old_bill_detail.ref_object_id]
        when 'SalaryPayment'
          new_bill_detail.ref_object_id = id_map[:salary_payments][old_bill_detail.ref_object_id]
        when 'ServiceBilling'
          new_bill_detail.ref_object_id = id_map[:service_billings][old_bill_detail.ref_object_id]
        end
        new_bill_detail.save
      end
      CommonExpenseDetail.where(common_expense_id: old_property.common_expenses.pluck(:id)).each do |old_common_expense_detail|
        new_common_expense_detail = old_common_expense_detail.dup
        new_common_expense_detail.common_expense_id = id_map[:common_expenses][old_common_expense_detail.common_expense_id]
        new_common_expense_detail.aliquot_id = id_map[:aliquots][old_common_expense_detail.aliquot_id]
        new_common_expense_detail.period_expense_id = id_map[:period_expenses][old_common_expense_detail.period_expense_id]
        case new_common_expense_detail.ref_object_class
        when 'Community'
          new_common_expense_detail.ref_object_id = if old_common_expense_detail.description == 'CustomFund'
                                                      id_map[:funds][old_common_expense_detail.ref_object_id]
                                                    else
                                                      self.id
                                                    end
        when 'Finiquito'
          new_common_expense_detail.ref_object_id = id_map[:finiquitos][old_common_expense_detail.ref_object_id]
          # when "Income"
          #   new_common_expense_detail.ref_object_id = id_map[:incomes][old_common_expense_detail.ref_object_id]
        when 'Interest'
          new_common_expense_detail.ref_object_id = id_map[:interests][old_common_expense_detail.ref_object_id]
        when 'Mark'
          new_common_expense_detail.ref_object_id = id_map[:marks][old_common_expense_detail.ref_object_id]
        when 'PropertyFine'
          new_common_expense_detail.ref_object_id = id_map[:property_fines][old_common_expense_detail.ref_object_id]
        when 'ProvisionPeriodExpense'
          new_common_expense_detail.ref_object_id = id_map[:provision_period_expenses][old_common_expense_detail.ref_object_id]
        when 'SalaryPayment'
          new_common_expense_detail.ref_object_id = id_map[:salary_payments][old_common_expense_detail.ref_object_id]
        when 'ServiceBilling'
          new_common_expense_detail.ref_object_id = id_map[:service_billings][old_common_expense_detail.ref_object_id]
        end
        new_common_expense_detail.save
      end
    end

    # revisar property users
    # revisar archivos
    # que hacer con los callbacks?
  end

  def copy_users(origin)
    properties.each do |new_property|
      old_property = origin.properties.find new_property.reference_id
      PropertyUser.where(property_id: old_property.id).each do |old_property_user|
        new_property_user = old_property_user.dup
        new_property_user.property_id = new_property.id
        new_property_user.save
      end
      settings.where(code: 'disable_users').update_all(value: 0)
    end
  end

  def old_properties_to_deactivate
    properties.where(old: true).eager_load(:property_transfers).joins(:balance).where('balances.money_balance >= 0').where(property_transfers: { id: nil })
  end

  ##########################
  #### INVOICE  PROCESS #####
  ##########################

  def may_i_invoice_you?
    last_closed_period_expense.present? && last_invoiced_period_expense.present? &&
      last_invoiced_period_expense.period <= last_closed_period_expense.period
  end

  def get_region
    return self[:timezone] if self[:timezone].present?

    case country_code
    when 'CL' then 'America/Santiago'
    when 'MX' then 'Mexico/General'
    when 'GT' then 'America/Guatemala'
    when 'SV' then 'America/El_Salvador'
    when 'BO' then 'America/La_Paz'
    else 'America/Santiago'
    end
  end

  def from_chile?
    country_code == 'CL'
  end

  def is_mexican?
    country_code == 'MX'
  end

  def timezone
    get_region
  end

  def timezone_offset
    ActiveSupport::TimeZone.seconds_to_utc_offset(ActiveSupport::TimeZone.find_tzinfo(timezone).utc_offset)
  end

  def generate_collection_excel
    period_expense = last_closed_period_expense
    document = []
    collection_sheet = {}
    collection_sheet[:name] = I18n.t('excels.billing_sheet.collection.name')
    collection_sheet[:title] = ['', I18n.t('excels.billing_sheet.title', period: I18n.l(period_expense.period, format: :short_month).capitalize)]
    collection_sheet[:subtitle] = ['', to_s]
    collection_sheet[:body] = []

    column_data_types = Hash.new('')

    collection_headers = ['']

    collection_headers += I18n.t(['property', 'deferred_collection', 'month_collection', 'pending', 'paid', 'date', 'description'].each {|s| s.prepend('excels.billing_sheet.headers.')})

    column_data_types[I18n.t('excels.billing_sheet.headers.deferred_collection')] = 'price'
    column_data_types[I18n.t('excels.billing_sheet.headers.month_collection')] = 'price'
    column_data_types[I18n.t('excels.billing_sheet.headers.paid')] = 'price'
    collection_sheet[:header] = collection_headers
    collection_sheet[:style] = collection_headers.map { |x| column_data_types[x] }
    collection_row = ['']

    ordered_properties = properties.includes(:unpaid_debts, :unpaid_debt_interests, uncomplete_payments: :assign_payments, debts: %i[assign_payments interest], community: [:settings, active_interest: :currency]).order_by_name
    Preloaders::PropertyPreloaders.preload_period_common_expenses(ordered_properties, period_expense.id, [:assign_payments, :common_expense_details, :period_expense, bill: [:active_common_expense, property: [:unpaid_debts, uncomplete_payments: :assign_payments], community: :settings]])
    Preloaders::PropertyPreloaders.preload_previous_unpaid_common_expenses(ordered_properties, period_expense.period, id, [:debts])
    ordered_properties.each do |prop|
      bills_and_details_hash = prop.common_expenses.map do |_ce|
        bill = prop.bills.joins(:period_expense).where(period_expenses: { id: period_expense.id }).first
        bill_details = bill&.bill_details
        { bill: bill, details: bill_details }
      end

      delayed_array = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('Bill', el[:details]) }.flatten
      service_billings = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('ServiceBilling', el[:details]) }.flatten
      incomes = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('Income', el[:details]) }.flatten
      reserve = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('Community', el[:details]) }.flatten
      marks = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('Mark', el[:details]) }.flatten
      provisions = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('ProvisionPeriodExpense', el[:details]) }.flatten
      fines = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('PropertyFine', el[:details]) }.flatten
      interests = bills_and_details_hash.map { |el| el[:bill].get_ref_objects('Interest', el[:details]) }.flatten
      total_service_billing = get_setting_value('common_expense_fixed') > 0 ? bills_and_details_hash.first[:bill].fixed_common_expense : service_billings.sum(&:price)
      total_service_billing = round(total_service_billing)
      total_incomes = round(incomes.sum(&:price))
      total_reserve = round(reserve.sum(&:price))
      total_marks = round(marks.sum(&:price))
      total_provisions = round(provisions.sum(&:price))
      total_fines = round(fines.sum(&:price))
      total_interests = round(interests.sum(&:price))
      delayed_for_this_property = delayed_array.sum { |v| round(v.price) } + total_interests
      this_month_for_property = total_service_billing + total_incomes + total_provisions + total_reserve + total_marks + total_fines
      total_this_month_for_property = delayed_for_this_property + this_month_for_property - round(bills_and_details_hash.sum { |el| el[:bill]&.payment_amount&.to_f })
      total_this_month_for_property = total_this_month_for_property < 0 ? 0 : total_this_month_for_property # Poner 0 si el pago es negativo
      collection_row.push(
        prop.name,                      # Nombre de la propiedad
        delayed_for_this_property,      # Cobros diferidos para esta propiedad
        this_month_for_property,        # Cobros de este mes para esta propiedad
        total_this_month_for_property   # Cobro total para esta propiedad
      )
      collection_row.concat(['', '', ''])
      unit_style = { style_array: collection_headers.map { |x| (column_data_types[x]).to_s } }
      collection_sheet[:body].append(
        content: collection_row,
        style: { alternated: true }.merge(unit_style)
      )
      collection_row = ['']
    end
    # Total
    collection_sheet[:body].append(
      content: ['', I18n.t('excels.billing_sheet.headers.total')] + [''] * 6,
      total: { vertical: true, to_total: (2..4).to_a }
    )
    collection_sheet[:row_offset] = 1 # Offset para cuadrar las sumas de los totales
    document.append(collection_sheet)
    format_to_excel(document, self)
  end

  def send_collection_excel(current_user = nil)
    file = generate_collection_excel
    period_expense = last_closed_period_expense
    title = "[#{self}] Planilla de cobro de #{period_expense.to_s.camelize}"
    body = I18n.t('mailers.collection_excel_sent_html', current_user: current_user.to_s)
    recipient = current_user
    origin_mail = 'contacto@comunidadfeliz.cl'

    # combinar
    UserMailer.notify_user_with_pdf_as_attachment(recipient, self, body, title, origin_mail, "Planilla de cobranza , #{period_expense} (#{self}).xlsx", file.to_stream.string, 'send_with_attachment').deliver
  end

  def bank_account_selected
    selected_bank_accounts.first
  end

  def accountables
    attendant_community_users.joins(:permissions).where(permissions: { code: 'issues', value: [EDIT_PERMISSION_VALUE, MANAGE_PERMISSION_VALUE] }).distinct
  end

  def update_certificate_number(new_value)
    self.certificate_number = new_value
    save
  end

  def last_periods(period_expense_id = nil, number_records, show_information_in_the_next_period)
    return [] unless number_records.positive?

    period_expense = period_expenses.find_by(id: period_expense_id) if period_expense_id.present?
    period_expense = get_open_period_expense if period_expense.nil?
    period_expense = period_expense.get_next.first if show_information_in_the_next_period

    period_expenses.history(period_expense.id, number_records).sort { |h| h.period }
  end

  def period_expense_history(period_expense_id = nil, number_records)
    show_information_in_the_next_period = false # Disable behavior different from Web

    period_expense_history = period_expenses
      .with_total_collected
      .with_total_expense(self)
      .where(id: last_periods(period_expense_id, number_records, show_information_in_the_next_period).pluck(:id))
      .order(period: :asc)
      .select(
        'period_expenses.*',
        'total_collected',
        'common_expense_and_aliquot.common_expense_price',
        'common_expense_and_aliquot.aliquot_price',
        'individual_consumption_amount.price individual_consumption_amount',
        'funds_amount.price funds_amount'
      )

    period_expense_history.each { |h| h.period = h.period - 1.month } if show_information_in_the_next_period

    period_expense_history
  end

  def notify_pending_payments(user)
    if self.uses_period_control?
      period_expense = self.get_open_period_expense
      pending_bundle_payments = BundlePayment.notify_pending(period_expense)
      pending_payments = Payment.notify_pending(period_expense)
    else
      pending_payments = Payment.notify_pending(nil, false, self)
      period_expense = nil
    end

    Log
      .create(
        value:
          'Notificó pago masivo múltiples '\
          "#{I18n.t('activerecord.models.property_user.other').downcase}, "\
          "Comunidad: #{self}",
        user_id: user.id,
        community_id: id,
        origin_class: 'BundlePayment,Payment'
      )

    {
      period_expense: period_expense,
      pending_bundle_payments: pending_bundle_payments,
      pending_payments: pending_payments
    }
  end

  def notification_pending_payments_in_progress?
    Delayed::Job.where(job_name: ['NotifyPaymentsJob', 'NotifyBundlePaymentsJob'], community_id: id).present?
  end

  def debts_and_defaults_xlsx_url
    DEBTS_AND_DEFAULTS_XLSX_URL
  end

  def defaulting_letters_pdf_url
    DEFAULTING_LETTERS_PDF_URL
  end

  def bills_pdf_url(period_expense_id)
    BILLS_PDF_URL.sub(':period_expense_id', period_expense_id || last_closed_period_expense.id.to_s)
  end

  def bills_xlsx_url(month, year)
    BILLS_XLSX_URL.sub(':month', month&.to_s || '').sub(':year', year&.to_s || '')
  end

  def collection_xlsx_url
    URI::Parser.new.escape COLLECTION_XLSX_URL.sub(':community_slug', slug)
  end

  def mixed_bills_pdf_url(period_expense_id)
    MIXED_BILLS_PDF_URL.sub(
      ':period_expense_id',
      period_expense_id || last_closed_period_expense.id.to_s
    )
  end

  def notify_payment_receipts_pdf_url(period_expense_id)
    NOTIFY_PAYMENT_RECEIPTS_PDF_URL.sub(
      ':period_expense_id',
      period_expense_id || last_closed_period_expense.id.to_s
    )
  end

  def short_bills_pdf_url(period_expense_id)
    SHORT_BILLS_PDF_URL.sub(
      ':period_expense_id',
      period_expense_id || last_closed_period_expense.id.to_s
    )
  end

  def not_notified_bundle_payments(from_paid_at, until_paid_at, payment_method, folio, amount)
    BundlePayment
      .joins(:period_expense)
      .where(period_expenses: { community_id: id })
      .where(receipt_notified: false, nullified: false)
      .where.not(payment_type: Payment.UNACCOUNTING_PAYMENT_TYPES)
      .filter_bundle_payments(
        from_paid_at: from_paid_at,
        until_paid_at: until_paid_at,
        payment_method: payment_method,
        folio: folio,
        amount: amount
      )
      .order(folio: :desc)
  end

  def get_surveys(published: true, open: true, answered: nil, page: 1, ended: false, user_id: nil)
    query = surveys.where(published: published)
    # non nil value means the ended argument was explicit in the query
    unless ended.nil?
      query = query.unavailable(self) if ended
      query = query.available(self) if open && !ended
    end
    query = Survey.answered?(query, user_id, answered) unless answered.nil?

    if user_id.present?
      query = query.with_user_read_check(user_id) # TODO: skip with_user_read_check if read field is not requested
        .joins(community: :users).where(users: { id: user_id }).distinct
      query = query
        .where(surveys: { answer_counting_method: Survey.filter_counting_methods(only_for_users_in_charge: false) })
        .or(
          query.where(
            surveys:        { answer_counting_method: Survey.filter_counting_methods(only_for_users_in_charge: true) },
            property_users: { in_charge: true }
          )
        )
    end

    query
      .order(published_at: :desc)
      .paginate(page: page, per_page: Survey::API_QUERY_PER_PAGE)
  end

  def generate_notify_bills_path(period_expense_id)
    period_expense = period_expenses&.select { |p| p.id.to_i == period_expense_id&.to_i }&.first
    payable = true if last_closed_period_expense&.id&.to_i == period_expense&.id&.to_i
    payable && !demo && period_expense&.bill_generated && !period_expense&.initial_setup ? NOTIFY_EMAILS_BILSS : nil
  end

  def calc_debit_commission(to_pay)
    return 0 unless to_pay

    # Bank transaction commission
    (to_pay.to_f * debit_commission.to_f / (1 - debit_commission.to_f)) +
      # Comunidad Feliz transaction commission
      ((to_pay / (1 - debit_commission.to_f)) * phi.to_f + delta.to_f)
  end

  def pending_payments_count
    return not_notified_payments_without_period_control.count unless uses_period_control?

    open_period_expense = get_open_period_expense
    pending_bundle_payments_size = open_period_expense.notifiable_bundle_payments.size
    pending_payment_size = open_period_expense.notifiable_payments.size
    pending_bundle_payments_size + pending_payment_size
  end

  def get_payments(report, from_paid_at, until_paid_at, payment_method, folio, amount, property, _integration)
    case report
    when nil, 'ALL'
      filter_payments(
        from_paid_at,
        until_paid_at,
        payment_method,
        folio,
        amount,
        property,
        integration,
        nullified: false
      )
    when 'UNRECOGNIZED'
      unrecognized_payments(
        from_paid_at,
        until_paid_at,
        payment_method,
        folio,
        amount
      )
    when 'NULLIFIED'
      filter_payments(
        from_paid_at,
        until_paid_at,
        payment_method,
        folio,
        amount,
        property,
        integration,
        nullified: true,
        visible: reuse_hidden_folios?
      )
    when 'NOT_NOTIFIED'
      not_notified_payments(
        from_paid_at,
        until_paid_at,
        payment_method,
        folio,
        amount
      )
    else
      []
    end
  end

  def filter_payments(from_paid_at, until_paid_at, payment_method, folio, amount, property, integration_present, nullified:, visible: nil)
    where_hash = { nullified: nullified, period_expenses: { community_id: id } }
    where_hash.merge!(property_id: property.id) if property

    payments =
      Payment
        .eager_load(
          :community_transaction,
          :period_expense,
          :purchase_order_payment,
          bill: :period_expense,
          finkok_response_payment: :finkok_response
        ).preload(
          property: [:aliquots, { first_in_charge: :profiles }, { first_user: :profiles }]
        ).where(where_hash)
        .filter_payments(
          from_paid_at: from_paid_at,
          until_paid_at: until_paid_at,
          payment_method: payment_method,
          folio: folio,
          amount: amount,
          visible: visible,
          country_code: country_code
        )

    payments = payments.online.where(exported: false) if integration_present
    payments = payments.preload(:applied_deductions) unless uses_period_control?

    return payments.order('period_expenses.period desc, payments.folio desc') if uses_period_control?

    payments.left_joins(:property).order(paid_at: :desc).merge(Property.order(name: :asc))
  end

  def not_notified_payments(from_paid_at, until_paid_at, payment_method, folio, amount)
    payments =
      Payment
        .joins(:period_expense)
        .where(period_expenses: { community_id: id })
        .where(receipt_notified: false, bundle_payment_id: nil, nullified: false)
        .eager_load(:community_transaction, :period_expense, :purchase_order_payment, bill: :period_expense, property: [first_in_charge: :profiles, first_user: :profiles])
        .where(profiles_users: { community_id: [id, nil] }, profiles: { community_id: [id, nil] })
        .where.not(payment_type: Payment.UNACCOUNTING_PAYMENT_TYPES)
        .filter_payments(
          from_paid_at: from_paid_at,
          until_paid_at: until_paid_at,
          payment_method: payment_method,
          folio: folio,
          amount: amount,
          country_code: country_code
        )
    payments = payments.includes(:applied_deductions) unless uses_period_control?
    uses_period_control? ? payments.standard_order : payments.order(paid_at: :desc).merge(Property.order(name: :asc))
  end

  def not_notified_payments_without_period_control
    Payment
      .joins(:period_expense)
      .where(period_expenses: { community_id: id })
      .where(receipt_notified: false, bundle_payment_id: nil, nullified: false)
      .where.not(payment_type: Payment.UNACCOUNTING_PAYMENT_TYPES)
      .where.not(property_id: nil)
      .standard_order
  end

  def unrecognized_payments(from_paid_at, until_paid_at, payment_method, folio, amount)
    unasigned_payments
      .filter_payments(
        from_paid_at: from_paid_at,
        until_paid_at: until_paid_at,
        payment_method: payment_method,
        folio: folio,
        amount: amount,
        country_code: country_code
      )
      .order('paid_at desc')
      .includes(:period_expense)
  end

  def closed_period_expense(params)
    return last_closed_period_expense unless params

    if params.id || (params.month && params.year)
      period_expenses
        .where(common_expense_generated: true)
        .where('? is null or ? = id', params.id, params.id)
        .where('? is null or ? = EXTRACT(MONTH from period)', params.month, params.month)
        .where('? is null or ? = EXTRACT(YEAR from period)', params.year, params.year)[0]
    end
  end

  def get_settings(code)
    code.present? ? settings.where(code: code) : settings
  end

  # object action
  def is_update_action_valid?
    active
  end

  # object action
  def is_show_account_summary_sheet_action_valid?
    get_setting_value('ass_enabled') == 1
  end

  # object action
  def is_show_bills_by_property_action_valid?
    get_setting_value('ass_enabled') == 1
  end

  # object action
  def is_bills_index_action_valid?
    self.integration&.setting_code('import_bills').blank?
  end

  def common_expense_by_bills_and_incomes?
    get_setting_value('common_expense_fixed') == 0
  end

  def full_bank_reconciliation_enabled?
    automatic_bank_reconciliation_enabled? && automatic_bank_reconciliation_onboarding_finished_enabled?
  end

  def automatic_bank_reconciliation_enabled?
    automatic_bank_reconciliation_module_enabled? && get_setting_value('automatic_bank_reconciliation').positive?
  end

  def automatic_bank_reconciliation_onboarding_finished_enabled?
    get_setting_value('automatic_bank_reconciliation_onboarding_finished').positive? && country_code == 'CL'
  end

  def automatic_bank_reconciliation_module_enabled?
    get_setting_value('module_automatic_bank_reconciliation_enabled').positive? && country_code == 'CL'
  end

  def campaign_space?
    get_setting_value('community_has_campaign_space') == 1
  end

  def with_full_access_setting?
    get_setting_value(:disable_users) == 1
  end

  def only_current_debts_in_pas?
    get_setting_value('debts_in_pas').zero?
  end

  def bank_reconciliation_initialized?
    period_expenses.where(first_bank_reconciliation: true).exists?
  end

  ###############################################
  ######### PROPERTY ACCOUNT STATEMENTS #########
  ###############################################

  def collect_pas(user_id, properties_ids)
    user = User.find_by(id: user_id.to_i)
    all_properties = properties_ids.nil?
    pdf = CombinePDF.new
    dirname = 'user_temp/property_account_statements/'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    properties_ids = properties.pluck(:id) if all_properties
    property_account_statements = Properties::GetLastPasForProperties.call(properties_ids).values

    property_account_statements.each do |pas|
      pdf << CombinePDF.new(FileGetter.safe_get_file(pas.pdf_statement.expiring_url(10)))
    end

    name = "user_temp/property_account_statements/estados_de_cuenta_#{all_properties ? '' : 'seleccionados_'}#{self.id}#{Time.now.to_i.to_s[6..10]}.pdf"
    pdf.save(name)
    file = File.new(name)
    title = I18n.t('mailers.collect_all_pas.title', community: self)
    file_name = "estados_de_cuenta_#{all_properties ? '' : 'seleccionados_'}#{self.id}#{Time.now.to_i.to_s[6..10]}.pdf"
    body = I18n.t('mailers.collect_all_pas.content', username: user.to_s)

    mail = UserMailer.notify_user_with_pdf_as_attachment(
      user,
      self,
      body,
      title,
      "notificaciones@mail.comunidadfeliz.cl",
      file_name,
      pdf.to_pdf,
      'send_with_attachment'
    )

    MailDeliver.safe_deliver_mail(mail)

    file.close
    File.delete(name)
  end

  ###############################################
  ######### PROPERTY ACCOUNT STATEMENTS #########
  ###############################################

  def pas_need_update?(property_ids)
    return if uses_period_control?

    property_ids ||= properties.pluck(:id)
    properties_last_pas_is_updated = Properties::LastPasIsUpdated.call(property_ids, id)

    !property_ids&.all? { |property_id| properties_last_pas_is_updated[property_id] }
  end

  def pas_already_updated_properties(properties_ids)
    properties_ids ||= properties.pluck(:id)
    properties_last_pas_is_updated = Properties::LastPasIsUpdated.call(properties_ids, id)
    already_updated_properties = properties_last_pas_is_updated.select { |property, updated| updated }

    already_updated_properties.keys
  end

  def format_currency(amount)
    ApplicationController.helpers.country_number_format(
      amount || 0.0,
      self.country_code,
      self.currency_symbol,
      self.get_rounding_decimals
    )
  end

  def has_scheduled_pas_notification?
    notify_pdf_message = I18n.t('jobs.notify_user_with_pdf.property_account_statement', email: '')

    community_jobs = Delayed::Job.where(community_id: self.id)

    community_jobs
      .where(job_name: NotifyUserWithPdfJob.to_s)
      .where('comments ILIKE ?', "%#{notify_pdf_message}%")
      .or(community_jobs.where(job_name: NotifyCommunityAccountStatements.to_s)).any?
  end

  def stp_active?
    get_setting_value('stp_payment_method').positive?
  end

  def is_one_debt_only?
    get_setting_value('one_debt_only').zero?
  end

  def date_first_closed_common_expense
    period_expenses.where(
      common_expense_generated: true
    ).joins(:common_expenses).minimum(:period)
  end

  def date_last_period_expense
    period_expenses.maximum(:period)
  end

  def calculate_last_periods_payments_sum
    last_closed_period = last_closed_period_expense.period
    period_range_filter = (last_closed_period - PAYMENTS_BY_PERIOD_TIME_SCOPE)..last_closed_period

    if uses_period_control?
      filtered_bills = bills.joins(:period_expense).where(
        period_expenses: { period: period_range_filter }
      ).pluck(:id, :period_expense_id)

      bills_ids = filtered_bills.transpose.first&.uniq
      period_expense_ids = filtered_bills.transpose.last&.uniq

      Payments::Sum.call(self, last_closed_period, period_expense_ids, bills_ids)
    else
      period_expense_periods = period_expenses.where(
        period: period_range_filter
      ).pluck(:period).sort.reverse

      Payments::SumByMonth.call(self, period_expense_periods)
    end
  end

  def service_billing_statistics(period_expense)
    period_expense = period_expense.get_next.first if settings.where(code: 'show_information_in_the_next_period', value: 1).exists?

    ActiveRecord::Base.connection.execute(
      PeriodExpense.service_billing_statistics(period_expense, period_expense.total_expense)
    )
  end

  def mexican_or_chilean?
    %w[MX CL].include?(country_code)
  end

  def chilean?
    country_code == 'CL'
  end

  def mexican?
    country_code == 'MX'
  end

  def uruguayan?
    country_code == 'UY'
  end

  def remunerations_outcomes_categories
    results = Category.get_community_outcomes_categories(self.id)
    selected = results.where(community_outcomes_setting: Constants::Categories::CL_BASE_COMMUNITY_REMUNERATIONS_CATEGORIES.index(I18n.t('views.category.new'))).pluck(:id)[0]

    return {
      options: results.pluck(:name, :id).push(['Nueva Categoría', 999999]),
      value: selected.nil? ? 999999 : selected
    }
  end

  def is_remunerations_outcomes_subcategory_by_model?
    get_setting_value('remuneration_service_billing_categories') == 0
  end

  def show_payment_assignment?
    get_setting_value('payment_show_assignment').zero?
  end

  def referential_period_expense(month:, year:, check_next_period_setting: true)
    search = are_year_and_month_valid?(month: month, year: year)
    period_expense = search ? get_period_expense(month, year, false) : last_closed_period_expense

    return period_expense unless check_next_period_setting

    only_current_month = get_setting_value('mes_corrido') == 1
    show_in_next_period = get_setting_value('show_information_in_the_next_period') == 1
    get_next_period = show_in_next_period && !only_current_month # If both settings are 1, rollback to the default behavior
    get_next_period ? period_expense&.get_next&.first : period_expense
  end

  def chilean_latam_campaign_valid?
    chilean? && online_payment_activated?
  end

  def redirect_to_residents?
    get_setting_value('redirect_to_residents') == 1
  end

  def property_user_validation_zip_filename
    I18n.t('views.property_user_validations.zip_filename', community_name: name.gsub(' ', '_').transliterate)
  end

  def sanitized_name
    name.gsub(/[^\p{L}\d ]+/,'')
  end

  def generate_property_user_validation_zip
    open_uri_max_string = OpenURI::Buffer::StringMax
    OpenURI::Buffer.const_set 'StringMax', 0 # Allow lightweight files to be stored as a Tempfile

    # TODO: use custom puvs directory if S3::FileUploader can handle custom s3 paths
    zipfile_path = "public/#{property_user_validation_zip_filename}.zip"
    documents = {}

    property_user_validations.includes(property: :property_users).each do |puv|
      next if puv.ownership_document.download_url.blank?

      documents[puv.filename_for_zip_download] = URI(puv.ownership_document.download_url).open
    end

    users.uniq.each do |user|
      documents[user.identity_document_filename(:front)] = URI(user.identity_document_front.download_url).open if user.identity_document_front.download_url.present?
      documents[user.identity_document_filename(:back)] = URI(user.identity_document_back.download_url).open if user.identity_document_back.download_url.present?
    end

    File.delete(zipfile_path) if File.exist?(zipfile_path)

    Zip::File.open(zipfile_path, create: true) do |zipfile|
      documents.each do |file_name, file|
        zipfile.add(file_name, file)
      end
    end

    OpenURI::Buffer.const_set 'StringMax', open_uri_max_string # restore to previous value

    zipfile_path
  end

  def funds_period_expenses_number
    period_expenses.where('initial_setup = false and common_expense_generated').size
  end

  def integration_with_period_control?
    uses_period_control? && integration.present?
  end

  def templates_by_country
    return PostTemplate.where(country_code: 'LA') unless %w[CL MX].include?(country_code.upcase)

    PostTemplate.where(country_code: country_code.upcase)
  end

  def templates_for_this_community
    templates_by_country.union(templates).order(created_at: :asc)
  end

  def old_enough_to_notify_users_creation?
    (Time.current.to_date - created_at.to_date).to_i > Constants::Communities::DAYS_TO_NOTIFY_USER_CREATION
  end

  def show_automatic_property_register_banner_in_bill?
    get_setting_value('show_automatic_property_register_banner_in_bill') == 1
  end

  def can_residents_publish_posts?
    get_setting_value('residents_can_publish_posts') == 1
  end

  def calculate_voting_population(in_charge: false)
    in_charge ? properties.joins(:in_charge).distinct.count('users.id') : users.distinct.count
  end

  def property_user_validation_enabled?
    property_user_validation_setting = get_setting('property_user_validation')
    property_user_validation_setting.update_column(:value, 1) if chilean? && property_user_validation_setting.value != 1

    property_user_validation_setting.value == 1
  end

  def closed_period_present?
    period_expenses.where(common_expense_generated: true).exists?
  end

  private

  def update_period_expenses
    UpdatePeriodExpenseDatesJob.perform_later(period_expense_ids: period_expenses.open.ids)
  end

  def build_default_categories
    default_categories = Countries.default_categories(country_code)
    categories << default_categories.map { |cat_hash| Category.new(cat_hash) }
  end

  def community_not_from_mexico(attributes)
    country_code != 'MX' || attributes['postal_code'].blank?
  end
end
