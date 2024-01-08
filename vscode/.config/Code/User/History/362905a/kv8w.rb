# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                       :integer          not null, primary key
#  annual                   :boolean          default(FALSE)
#  assignable_imported      :boolean
#  compensation             :boolean          default(FALSE)
#  completed                :boolean          default(FALSE)
#  confirmed                :boolean          default(FALSE)
#  confirmed_at             :datetime
#  description              :string
#  estimate_future_debt     :boolean          default(TRUE)
#  exported                 :boolean          default(FALSE)
#  folio                    :integer
#  generated_pdf            :boolean          default(FALSE)
#  importer_type            :string
#  irs_billed               :boolean          default(FALSE)
#  irs_billed_at            :datetime
#  irs_status               :integer          default(0)
#  issued                   :boolean          default(FALSE)
#  notifying                :boolean          default(FALSE)
#  nullified                :boolean          default(FALSE)
#  nullified_at             :datetime
#  paid_at                  :date
#  payment_number           :string
#  payment_type             :integer          default("transference")
#  price                    :decimal(19, 4)   default(0.0)
#  receipt                  :string
#  receipt_notified         :boolean          default(FALSE)
#  receipt_notified_at      :datetime
#  receipt_updated_at       :datetime
#  source                   :string           default("form")
#  state                    :integer          default(1)
#  temp_money_compensation  :decimal(19, 4)   default(0.0)
#  to_bill                  :boolean          default(FALSE)
#  tracking_number          :string
#  undid                    :boolean          default(FALSE)
#  user_mail                :string
#  user_name                :string
#  visible                  :boolean          default(TRUE)
#  created_at               :datetime
#  updated_at               :datetime
#  bill_id                  :integer
#  bundle_payment_id        :integer
#  deduction_id             :bigint
#  excel_upload_id          :integer
#  importer_id              :integer
#  nullified_transaction_id :integer
#  nullifier_id             :integer
#  origin_payment_id        :integer
#  period_expense_id        :integer
#  property_id              :integer
#  property_transaction_id  :integer
#  reference_id             :integer
#  user_id                  :integer
#
# Indexes
#
#  index_payments_on_bill_id                        (bill_id)
#  index_payments_on_deduction_id                   (deduction_id)
#  index_payments_on_importer_type_and_importer_id  (importer_type,importer_id)
#  index_payments_on_origin_payment_id              (origin_payment_id)
#  index_payments_on_period_expense_id              (period_expense_id)
#  index_payments_on_property_id                    (property_id)
#  index_payments_on_property_transaction_id        (property_transaction_id)
#
# Foreign Keys
#
#  fk_rails_4373e56d2e  (deduction_id => deductions.id)
#
class Payment < ApplicationRecord
  include ObjectActions::ObjectActionHelper
  include ApplicationHelper
  include CommunityTransactionModule
  include Webpay
  include Formatter
  include PaymentPdfGenerationLib
  include PaymentsCommon
  include Importable
  include AttachmentTimerUpdater
  include PrepareInvoiceHash
  require 'rqrcode'

  enum source: ::Constants::Payment::SOURCES, _prefix: true

  attr_accessor :massively_imported
  attr_accessor :general_public

  MAX_STP_AMOUNT = 999_999_999_999.99
  MIN_STP_AMOUNT = 0.01

  # has_one :cached_pdf
  has_many   :assign_payments, dependent: :destroy
  belongs_to :bill, optional: true # referencia por temporalidad
  belongs_to :bundle_payment, optional: true
  has_one    :buy_order, as: :payable
  has_many   :campaign_data
  has_one    :finkok_response_payment, dependent: :destroy
  has_one    :grouped_finkok_response, through: :finkok_response_payment, source: :finkok_response
  has_one    :active_grouped_finkok_response, ->{ where(cancelled: false) }, through: :finkok_response_payment, source: :finkok_response
  has_one    :community_transaction, -> { where(origin_class: 'Payment') }, foreign_key: 'origin_id'
  has_many   :compensation_payments, class_name: 'Payment', foreign_key: :origin_payment_id, dependent: :destroy
  has_one    :credit_purchase_order_payment, -> { PurchaseOrderPayment.credit }, as: :payable, class_name: 'PurchaseOrderPayment'
  has_one    :finkok_response, -> { where(irs_type: FinkokResponse.irs_types['factura']).limit(1) }, as: :invoiceable
  belongs_to :deduction, optional: true
  belongs_to :excel_upload, foreign_key: 'importer_id', inverse_of: :payments,
                            class_name: 'ExcelUpload', optional: true
  belongs_to :importer, polymorphic: true, inverse_of: :payments, optional: true

  has_one :nullified_transaction, -> { where(reversed: true) }, as: :origin, class_name: 'BusinessTransaction', dependent: :destroy
  has_one :property_transaction, -> { where(reversed: false) }, as: :origin, class_name: 'BusinessTransaction', dependent: :destroy

  belongs_to :nullifier, class_name: 'User', foreign_key: :nullifier_id, optional: true
  belongs_to :period_expense, optional: true # referencia por temporalidad
  belongs_to :property, optional: true
  has_one    :purchase_order_payment, as: :payable
  belongs_to :user, optional: true

  # Through associations
  has_one    :community, through: :period_expense
  has_many   :debts_assigned_to, through: :assign_payments, source: :debt
  has_many   :applied_deductions, -> { where(applied: true) }, through: :debts_assigned_to, source: :deductions
  has_one    :finkok_complement, through: :finkok_response

  # Dependant through associations
  has_one    :mx_company, through: :community

  attr_accessor :allow_zero_price
  attr_accessor :mark_as_reconciled
  attr_accessor :receipt_info_unchanged
  attr_accessor :skip_pdf_generation
  attr_accessor :skip_update_transaction
  attr_accessor :update_paid_at
  attr_accessor :bank_transaction_id
  attr_accessor :notify_on_create
  attr_accessor :generate_invoice_on_create

  attr_writer :bank_account_id

  # validates_presence_of :property_id
  before_validation :set_generate_invoice_on_create, on: :create, if: proc { |pa| pa.community&.mx_company.present? }
  before_validation :round_price, unless: :massively_imported
  validate :property_not_old, unless: :massively_imported
  validates :generate_invoice_on_create, exclusion: { in: ['true', true] }, unless: proc { |pa| pa.community&.mx_company.present? }
  validates :price, numericality: { greater_than: 0.0, less_than_or_equal_to: 2_147_483_647.0 }, if: -> { allow_zero_price.nil? || allow_zero_price == false }
  validates :visible, inclusion: { in: [true] }, unless: proc { |pa| pa.nullified }
  validate :not_online?, if: proc { |pa| pa.id.present? }
  validate :bill_in_community, if: proc { |pa| pa.will_save_change_to_bill_id? }
  validate :property_in_community, if: proc { |pa| pa.will_save_change_to_property_id? }
  validate :not_issued?
  validates_presence_of :paid_at, if: proc { |pa| !pa.pending? }
  validates_presence_of :property_id, if: proc { |pa| pa.annual or pa.pending? }
  validates_presence_of :price
  validates_presence_of :user, unless: :massively_imported
  validate :paid_at_validation, if: :paid_at_changed?

  delegate :bank_account_id, to: :community_transaction, allow_nil: true

  # Set folio for all payments that aren't adjustments and if the setting is set to folio required.
  after_create :set_folio!, if: proc { (!adjustment? || self.community.get_setting_value('folio_required_for_adjustments') == 1) && update_paid_at.nil? }
  before_create :assign_bill, if: proc { |pa| pa.bill_id.blank? && pa.property_id.present? }
  after_save :update_community_transaction, if: :generate_community_transaction?
  after_save :receipt_info_unchanged?, unless: proc { |pa| pa.pending? }
  after_commit :delay_generate_pdf, unless: proc { |pa| pa.pending? }
  after_commit :generate_invoice, on: :create, if: :generate_invoice_on_create
  after_save :log_changes
  before_destroy :destroy_community_transaction
  before_destroy :validate_destroy, :validate_online_payment
  before_save :prevent_payment_type_change, :fill_user

  mount_uploader :receipt, DocumentationUploader

  delegate :contact_email, to: :community
  delegate :contact_name, to: :community
  delegate :name, to: :property, prefix: true, allow_nil: true
  delegate :name, to: :community, prefix: true
  delegate :get_locale, to: :community

  scope :standard_order, -> { joins(:period_expense).order(PeriodExpense.arel_table['period'].desc, folio: :desc) }
  # Use this scope to get payments that are not "Ajuste"
  scope :accountable, -> { where.not(payment_type: Payment.UNACCOUNTING_PAYMENT_TYPES) }
  scope :active, -> { where('state = ? and nullified = ?', Payment.reversed_status_hash('Pagado'), false).includes(:assign_payments) }
  scope :active_without_preloads, -> { where('state = ? and nullified = ?', Payment.reversed_status_hash('Pagado'), false) }
  scope :not_adjustment, -> { where.not(payment_type: Payment.payment_types[:adjustment] ) }
  scope :not_pending, -> { where.not(payment_type: Payment.payment_types[:pending] ) }
  scope :nor_nullified_or_irs_billed, -> { where(nullified: false, irs_billed: false) }
  scope :irs_pending, -> { not_adjustment.nor_nullified_or_irs_billed.where.not(irs_status: Payment.irs_billing_statuses) }
  scope :irs_billing, -> { not_adjustment.nor_nullified_or_irs_billed.where(irs_status: Payment.irs_billing_statuses) }
  # Pagos de tipo online
  scope :online, -> { where(payment_type: [6, 7]) }
  scope :one_community, ->(community_id) { includes(:property).where(properties: { community_id: community_id }) }
  scope :last_payments, lambda {
    accountable
      .where(nullified: false)
      .select('distinct on (payments.property_id) payments.*')
      .order(:property_id, paid_at: :desc)
  }
  scope :valid, -> { accountable.active_without_preloads }

  scope :with_owner_full_name, lambda {
    joins(
      <<~SQL
        LEFT OUTER JOIN "properties" ON "properties"."id" = "payments"."property_id" left join lateral (
          select distinct on(pu.property_id)
            pu.property_id,
            u.email email,
            lower(
              regexp_replace(
                trim(
                  concat(
                    concat(u.first_name, ' '),
                    concat(u.last_name, ' '),
                    concat(u.mother_last_name)
                  )
                ), '(( ){2,}|\t+)', ' ', 'g'
              )
            ) full_name
          from property_users pu
          join users u on u.id = pu.user_id
          where pu.property_id = properties.id and pu.active
          order by pu.property_id asc, pu.role = 'owner' desc
        ) owners on owners.property_id = properties.id
      SQL
    )
  }

  scope :with_period_summaries, lambda {
    joins(:period_expense)
    joins(
      <<~SQL
        left join lateral (
          select
          b.id bill_id,
          replace(
            to_char(pe.period, '{mnth} - yyyy'),
            '{mnth}',
            case extract(month from pe.period)
              #{(1..12).map { |i| "when #{i} then \'" + I18n.t('date.month_names')[i] + "'\n" }.join('')}
            end
          ) payment_period,
          pe.period period_expense_period
          from bills b
          join period_expenses pe ON pe.id = b.period_expense_id
          where b.id = payments.bill_id
        ) period_expense on period_expense.bill_id = payments.bill_id
      SQL
    )
  }

  scope :preload_finkok_responses, lambda {
    eager_load(
      :active_grouped_finkok_response,
      finkok_response: :finkok_complement
    )
  }

  scope :with_formatted_date, lambda { |field, field_alias|
    select(
      <<~SQL
        coalesce(
          replace(
            to_char(#{field}, 'dd {mnth}. yyyy'),
            '{mnth}',
            case extract(month from #{field})
              #{(1..12).map { |i| "when #{i} then \'" + I18n.t('date.abbr_month_names')[i] + "'\n" }.join('')}
            end
          ),
          ''
        ) #{field_alias}
      SQL
    )
  }

  scope :order_by_payment_type_name, lambda { |direction|
    order(
      <<~SQL
        case payments.payment_type
          #{
            Payment
              .payment_types
              .sort_by { |p| Payment.human_enum_name(:payment_type, p) }
              .map { |p| p[1] }
              .each_with_index
              .map { |p, i| "when #{p} then #{i}" }
              .join(' ')
          }
        end #{ direction }
      SQL
    )
  }

  FILE_AVAILABILITY_TIME = 10
  PAYMENT_ORIGIN = %w[default discount].freeze

  enum payment_type: { cheque:           0,
                       cash:             1,
                       transference:     2,
                       adjustment:       3,
                       deposit:          4,
                       red_compra:       5,
                       webpay:           6,
                       online_payment:   7,
                       pac_pat:          8,
                       pending:          9,
                       credit_card:      10,
                       digital_currency: 11,
                       debt_relief:      12,
                       clearing:         13,
                       debt_card:        14,
                       down_payment:     15,
                       spei: 16 }

  COMMON_PAYMENT_TYPES = %w[cheque cash transference adjustment deposit].freeze
  MX_INVOICE_PAYMENT_TYPES = %W[pending credit_card digital_currency debt_relief clearing debt_card down_payment spei].freeze
  ONLINE_PAYMENT_TYPES = %w[webpay online_payment spei].freeze
  UNACCOUNTING_PAYMENT_TYPES = %w[adjustment pending].freeze

  DEPRECATED_WEBPAY_TYPE_INDEX = 6
  ONLINE_PAYMENT_TYPE_INDEX = 7

  RECEIPT_RELEVANT_ATTRS = %w[
    completed generated_pdf receipt receipt_notified
    receipt_notified_at updated_at notifying
  ].freeze

  def self.UNACCOUNTING_PAYMENT_TYPES
    UNACCOUNTING_PAYMENT_TYPES.map { |e| Payment.payment_types[e] }
  end

  def accounting?
    !UNACCOUNTING_PAYMENT_TYPES.include?(payment_type)
  end

  def property_not_old
    errors.add(:property, :old) if property&.old && id.blank? && (-1 * property&.get_money_balance.to_f < price.to_f)
  end

  def not_online?
    return unless online? && (will_save_change_to_price? || will_save_change_to_property_id?)

    errors.add(:payment_type, :online)
  end

  def not_issued?
    return unless issued &&
                  !notified_fields_only &&
                  changes.keys.any? { |changed_attr| %w[bill_id property_id period_expense_id price nullified].include?(changed_attr) }

    errors.add(:issued, :period_closed)
  end

  # returns true if the fields to update are only to register notification actions
  def notified_fields_only
    (%w[receipt_notified receipt_notified_at notifying] | self.changed_attributes.keys).length <= 3
  end

  def bill_in_community
    errors.add(:bill, :not_found) unless bill.present? && bill.property_id == property_id
  end

  def property_in_community
    return if property&.community_id == period_expense&.community_id

    errors.add(:property, :not_found)
  end

  def self.reversed_payment_origin(val)
    PAYMENT_ORIGIN.find_index(val)
  end
  # after_save :request_calculate
  # before_destroy :request_calculate
  ########################
  ##   BEFORE DESTROY   ##
  ########################

  def validate_destroy
    throw(:abort) if self.issued
  end

  def validate_online_payment
    # Every successful online payment (Webpay)
    throw(:abort) if online? && confirmed?
  end

  def update_valid_folio
    community.payment_folio&.next
  end

  def prevent_payment_type_change
    # Return true if new record
    created_at_changes = changes_to_save[:created_at]
    return true if !self.id.present? || (created_at_changes.present? && created_at_changes[0].nil?)

    payment_type_changes = changes_to_save[:payment_type]

    # Cannot change payment type FROM and TO online payment
    throw(:abort) if payment_type_changes.present? && (payment_type_changes & ONLINE_PAYMENT_TYPES).present?
  end

  def fill_user
    self.user_name = user&.name unless user_name.present?
    self.user_mail = user&.email unless user_mail.present?
    true
  end

  def round_price
    community = PeriodExpense.find_by(id: self.period_expense_id)&.community
    return unless community.present?

    self.price = community.round(price)
  end

  ####################
  ##   After Save   ##
  ####################

  # def request_calculate
  #   self.property.community.get_open_period_expense.set_request_calculate
  # end
  def update_community_folio(folio)
    community.payment_folio.update(folio: folio)
  end

  def set_max_folio
    max_folio = Communities::FoliosQueries.max_folio(community) + 1

    update(folio: max_folio)
    update_community_folio(folio)
  end

  def set_folio # SIEMPRE SUBE! CUIDADO
    return if bundle_payment_id.present?

    update_column(:folio, community.up_payment_folio)
  end

  def set_folio! # SIEMPRE SUBE! CUIDADO
    return if bundle_payment_id.present?

    repeated_folio = Communities::FoliosQueries.folio_repeated?(community, folio || community.payment_folio.next, id)

    return set_max_folio if repeated_folio
    return set_folio unless community.can_edit_folio? && folio.present?

    update_community_folio(folio)
  end

  def set_community_transaction_data(ct)
    return ct if skip_update_transaction
    return ct unless should_generate_transaction

    ct.comments             = I18n.t('models.payment.ct_comments', folio: self.folio,  property: self.property, description: self.description)
    ct.folio                = self.folio
    ct.document_number      = self.payment_number
    ct.payment_type         = self.get_payment_type
    ct.name                 = self.property.to_s
    ct.description          = self.description.to_s
    ct.transaction_value    = self.price
    ct.account              = 'Cuenta Corriente' # self.reserve_fund ? "Fondo de reserva" :
    ct.paid                 = !self.nullified
    ct.transaction_date     = self.paid_at
    ct.accountable_date     = confirmed_at ? CommunityTransactions::GetAccountableDate.call(self) : paid_at
    ct.payment_date         = self.paid_at
    ct.origin_url           = Rails.application.routes.url_helpers.bills_path(search: self.property.to_s)
    # Si el periodo de paid_at corresponde a un period_expense cerrado, ir automáticamente a la conciliación bancaria abierta
    payment_period_expense  = self.community.get_period_expense(self.paid_at.month, self.paid_at.year)
    ct.period_expense       = payment_period_expense.bank_reconciliation_closed ? self.community.current_bank_reconciliation : payment_period_expense
    ct.state_id             = resolve_ct_state_id
    ct.bank_transaction_id  = self.bank_transaction_id || ct.bank_transaction_id
    ct.bank_account_id      = @bank_account_id || ct.bank_account_id
    ct.save
    ct
  end

  def should_generate_transaction
    visible && !source_compensation? && bundle_payment_id.blank? && !adjustment? && !pending? && !clearing?
  end

  def resolve_ct_state_id
    case ::Constants::Payment::SOURCES.fetch(source.underscore.to_sym)
    when ::Constants::Payment::SOURCES[:match_feliz] # is 'match feliz'
      # All match_feliz creted payments are reconciliated/paid (it's assumed match_feliz is fully activated)
      CommunityTransaction.get_state('paid')
    when ::Constants::Payment::SOURCES[:excel]
      return CommunityTransaction.get_state('paid') unless community.full_bank_reconciliation_enabled?

      match_feliz_depending_state
    when ::Constants::Payment::SOURCES[:online]
      # Online and Excel imported payments, follow the same rule: When MF active, the transaction is pending.
      match_feliz_depending_state
    when ::Constants::Payment::SOURCES[:form]
      # When the CF Payment form is used to create payments, then the checkbox is considered.
      # The checkbox is not shown when MF is active. In that case, the state is default for pending
      if mark_as_reconciled.present?
        payment_reconciled?(mark_as_reconciled) ? CommunityTransaction.get_state('paid') : CommunityTransaction.get_state('pendding')
      else
        match_feliz_depending_state
      end
    else
      CommunityTransaction.get_state('pendding')
    end
  end

  def payment_reconciled?(mark_as_reconciled)
    mark_as_reconciled.to_s == 'true' || reconciled?
  end

  def log_changes(user_id: nil)
    fields_changed = saved_changes.except!(:created_at, :updated_at).map { |k, v| "#{k} (#{v.join(' -> ')})" }.join(', ')
    return unless saved_changes.present?

    Log.create(
      value: "Atributos actualizados: [#{fields_changed}]", user_id: user_id,
      community_id: community.id, origin_class: self.class.name, origin_id: id
    ) if !Rails.env.test?
  end

  #################
  ##   Methods   ##
  #################

  def from_edifito?
    Payment.joins("INNER JOIN importers i ON i.id = payments.importer_id AND payments.importer_type = 'Importer'").where(payments: {id: self.id}, i: { importer_type: 'Payment' }).exists?
  end

  def assignable?
    assignable = if from_edifito?
                   assignable_imported.present?
                 else
                   assignable_imported != false
                 end

    !completed && !nullified && property && confirmed && assignable
  end

  def assign_common_expense(compensation: true, debt_ids: [], debts_amount: {}, cached: false, deduction_ids: [])
    return unless assignable?

    debts =
      if cached
        property.debts.reject(&:paid).sort_by { |d| [d.priority_date, d.id] }
      else
        property.debts.where(paid: false)
          .includes(:interest, assign_payments: [:payment], interests: [:debt], period_expense: [:discounts])
          .order('priority_date ASC').order('id ASC')
      end

    debts = debts.reverse if property.community.get_setting_value('automatic_payment_assignment_priority') == 1

    selected_debts = debts.select { |debt| debt_ids.include?(debt.id) }
    # order debts to pay selected debts first
    debts = (selected_debts + debts).uniq if selected_debts.any?


    Payments::AssignationImporter.new(self, debts, compensation, debts_amount, deduction_ids).call if debts.present?
  end

  def use(amount, debt, compensation_or_interest = true)
    return 0 unless !self.completed && amount > 0 && !self.nullified

    # Volvemos a hacer la consulta, a veces el valor almacenado en el objeto juega una mala pasada
    available_money = Payment.includes(:assign_payments).find(id).available_money
    money = available_money <= amount ? available_money : amount
    # Cobrar interés hasta la fecha
    return 0 unless money.positive?

    assign_payment = self.assign_payments.new(
      price: money, debt_id: debt.id, assigned_at: confirmed_at, paid_at: paid_at
    )
    community_interest = community.current_interest
    # Si se anula el pago, hay que saber desde dónde recuperar el interés
    assign_payment.should_bill_interest = debt.last_interest_bill_date
    assign_payment.save

    # Se considera la fecha de pago o la actual
    self.paid_at ||= self.created_at

    if compensation_or_interest
      debt.last_interest_bill_date = debt.priority_date if debt.last_interest_bill_date.blank?
      if self.paid_at < (debt.last_interest_bill_date - 1.minute) && debt.last_interest_bill_date > (debt.priority_date + 1.minute)
        # Pago antes de la última facturación, pero ya se cobró interest
        start_date = [self.paid_at, debt.priority_date].max.to_date
        end_date = (debt.last_interest_bill_date + 1.minute).to_date
        days = (end_date - start_date).to_i

        self.generate_compensation(debt, community_interest, days, money)
      end
    end
    # Verificar que cerró el payment /(se gastó la plata )
    self.validate_complete
    money
  end

  def generate_compensation(debt, community_interest, days, money, extra_description = '')
    if (community.get_setting_value('compensaciones_interes') == 1) || (debt.interests.blank? && debt.interest.blank?)
      return false
    end


    payment = nil
    # Revisar pertinencia del cobro de interes
    if debt.interest_pertinency(community_interest) && !source_compensation?

      # No debe compensar más que la deuda original
      utilization = (debt.price > (money + self.temp_money_compensation)) ? self.temp_money_compensation : debt.price - money

      money += utilization
      interest_price = community_interest.calculate_interest(money, [days, 0].max).to_f
      if interest_price.positive?
        payment = Payment.new(
          paid_at: paid_at,
          price: interest_price,
          property_id: property_id,
          user_id: user_id,
          period_expense_id: period_expense_id,
          bill_id: bill_id,
          payment_type: 3, # AJUSTE
          origin_payment_id: id,
          description: "Compensación por interés cobrado previamente (#{days} días, por: $#{money})."\
                       "#{extra_description}",
          source: ::Constants::Payment::SOURCES[:compensation]
        )
        # payment.state = self.state
        payment.save
        payment.confirm if confirmed? # extra validation
        # SI se genera la transaction, el interés puede que aún no la tenga.

      end

      # debt.temp_money_compensation = 0
      # debt.save
      self.temp_money_compensation = self.temp_money_compensation - utilization
    else
      # interest = debt.interest
      # if interest.present?
      #   origin_debt = interest.origin_debt
      #   if origin_debt.present?
      #     origin_debt.temp_money_compensation = origin_debt.temp_money_compensation + money
      #     origin_debt.save
      #   end
      # end

      self.temp_money_compensation = self.temp_money_compensation + money
    end
    self.save
    payment
  end

  def generate_discount_adjust(discount_amount, discount_name)
    payment = Payment.create(
      paid_at: paid_at, price: discount_amount,
      property_id: property_id, user_id: user_id,
      period_expense_id: period_expense_id,
      bill_id: bill_id, payment_type: 3, # ajuste
      description: discount_name,
      origin_payment_id: id,
      source: ::Constants::Payment::SOURCES[:discount]
    )
    payment.confirm if confirmed?
  end

  # SOLO POR TEMPORALIDAD; para saber cual era el bill activo en el momento que se genero el pago
  def assign_bill
    self.bill_id = self.property.get_last_bill.id if self.property.present? && self.property.get_last_bill.present?
  end

  # [TO DELETE] similar a Bill::get_money_collected
  def self.avaible_money_for_period(properties, period_expense)
    Property.joins(
      'LEFT JOIN common_expenses ON common_expenses.property_id = properties.id '
    ).joins(
      'LEFT JOIN payments ON payments.property_id = properties.id '
    ).joins(
      'LEFT JOIN assign_payments ON assign_payments.payment_id = payments.id '
    ).select(
      '(sum(payments.price)) as payment_price, sum(assign_payments.price) as assign_payments_price, sum(common_expenses.price) as common_expenses_price , properties.id'
    ).where(
      'properties.id in (?) and common_expenses.period_expense_id = ? and payments.completed = ?', properties, period_expense.id, false
    ).group('properties.id').to_a.sum do |e|
      [e.payment_price.to_f - e.assign_payments_price.to_f, e.common_expenses_price.to_f].min
    end
  end

  def self.get_money_paid_for_month(date, community_id)
    Payment.joins(:property).where("date_trunc('month', paid_at) = ?", date.at_beginning_of_month).where(properties: { community_id: community_id }).sum(:price)
  end

  # DEPRECADO
  def set_issued
    self.update_column :issued, true # saltar validadores
  end

  def status
    Payment.status_hash[self.state]
  end

  def self.status_hash
    { 1 => 'Por Verificar', 2 => 'Pagado', 3 => 'Rechazado' }
  end

  def self.reversed_status_hash(val = nil)
    if val
      Payment.status_hash.invert[val]
    else
      Payment.status_hash.invert
    end
  end

  def assigned_money
    self.assign_payments.to_a.sum(&:price)
  end

  def available_money
    self.price - self.assigned_money
  end

  def validate_complete
    self.update_column :completed, (self.assign_payments.sum(:price) == self.price)
  end

  def get_receipt
    receipt
  end

  def set_receipt(other)
    self.receipt = other
  end

  def has_receipt?
    receipt.present?
  end

  # CREATE TRANSACTION
  def create_transaction
    return if property_transaction.present? || property.blank? || property.community.integration.present? || pending?

    pt = BusinessTransaction.create(
      transaction_value: price, balance_id: property.balance_id,
      origin_id: id, origin_type: self.class.name, transaction_date: Time.now
    )
  end

  def destroy_assign_payments(compensation: false)
    # destroy assigned payments and create new ones but keep selected debt
    debt_ids = assign_payments.map(&:debt_id)
    assign_payments.each(&:destroy)
    Deduction.bulk_revert(Deduction.where(debt_id: debt_ids).pluck(:id))
    assign_common_expense(compensation: compensation, debt_ids: debt_ids.compact)
  end

  def confirm!
    confirm
  end

  def confirm(confirmed_at = Time.now, with_bill = true, delay_pdf = false, debt_ids = [], debts_amount = {}, deduction_ids = [])
    return if !property.present? || pending?

    debts_amount = {} if debts_amount.any? && debts_amount.values.sum != price

    self.state = Payment.reversed_status_hash['Pagado']
    self.confirmed_at = confirmed_at
    self.confirmed = true

    # actualizar period expense
    self.period_expense_id = self.community.get_open_period_expense.id

    # Asignamos el bill activo, si ya tiene, este rectificado en close period expense
    self.assign_bill if (!self.bill_id.present? && with_bill) or previous_changes["payment_type"].to_a.include?("pending")

    # validar si fue creada completamente
    if self.save
      self.assign_common_expense(
        compensation: self.community.get_setting_value('compensaciones_interes') == 0,
        debt_ids: debt_ids,
        debts_amount: debts_amount,
        deduction_ids: deduction_ids
      )

      self.create_transaction

      # checkear si se pago el bill, si ya tiene, este rectificado en close period expense
      if with_bill
        bill = Bill.includes(:bill_details, :payments).where(id: self.bill_id).first
        bill.check_status if bill.present?
      end

      # Validar si se completó el pago
      self.validate_complete
    end
  end

  def unconfirm
    self.update(confirmed_at: nil, confirmed: false)
  end

  def nullify!(nullifier_id = nil)
    return false if active_grouped_finkok_response.present? || online?

    if webpay? && !bundle_payment.present?
      transaction_results = buy_order&.webpay_transaction_results
      can_nullify = transaction_results&.first&.nullify.present? || transaction_results&.last&.nullify.present?
      # Return if webpay transactions cannot be nullified or payment is not confirmed
      return false if !can_nullify || !confirmed?

      # Get webpay utilities object
      wps = WebpayTransaction.new(ENV['TRANSBANK_NULLIFY_ENDPOINT'])
      # Send a request to webpay to nullify each transaction
      nullified = true
      transaction_results.each do |result|
        nullified = (wps.nullify(result) ||
                    (!result.nullify && result.get_payment_type == I18n.t('webpay.credit'))) &&
                    nullified
      end

      # Return if webpay transactions couldn't be nullified
      return false unless nullified
    end
    Payments::Nullifier.new(self, nullifier_id, community).call
  end

  def nullifyable?
    !online? && !issued && !nullified
  end

  def hide
    return false unless nullified && update_column(:visible, false)

    destroy_community_transaction
    destroy_business_transactions
    property&.update_future_receipts(created_at)

    true
  end

  def destroy_business_transactions
    property_transaction&.destroy
    nullified_transaction&.destroy
  end

  def delay_generate_pdf
    return if !confirmed || skip_pdf_generation ||
              online? || destroyed? || generate_invoice_on_create ||
              (receipt.present? && receipt_info_unchanged) || new_record?

    update_column(:generated_pdf, false)
    generate_pdf(notify: notify_on_create == 'true')
  end

  def update_pdf
    return if skip_pdf_generation

    update_column(:generated_pdf, false)
    generate_pdf(notify: notify_on_create == 'true')
  end

  def info_changed?(params)
    self.paid_at.to_date != params[:paid_at]&.to_date ||
      self.price.to_f != params[:price].to_f ||
      self.folio != params[:folio].to_i ||
      self.payment_type != params[:payment_type] ||
      self.description != params[:description]
  end

  def receipt_info_unchanged?
    self.receipt_info_unchanged = (saved_changes&.keys.to_a - RECEIPT_RELEVANT_ATTRS).blank?
  end

  def generate_pdf(notify: false, notify_admin: false)
    message = I18n.t('jobs.generate_payment_pdf')
    GeneratePaymentPdfJob.perform_later(
      _community_id: community.id, payment_id: id, _message: message
    )

    try_notify_receipt(community_id: community.id) if notify
    try_notify_receipt_to_admin if notify_admin
  end

  def generate_automatic_payment_pdf(notify_automatic_payment: true)
    GeneratePaymentPdfJob.perform_later(
      _community_id: community.id, payment_id: id, _message: I18n.t('jobs.generate_payment_pdf')
    )

    try_notify_automatic_receipt if notify_automatic_payment
  end

  def pdf_hash
    PaymentPdfGenerationLib.generate_payment_pdf_hash(
      payment: self,
      community:
        Community
          .includes(community_users: :user)
          .find_by(id: period_expense.community_id)
    )
  end

  def self.pdf_hash_grouped(payments, community_id, finkok_response_id)
    PaymentPdfGenerationLib.generate_payments_grouped_pdf_hash(
      payments: payments,
      community:
        Community
          .includes(community_users: :user)
          .find_by(id: community_id),
      finkok_response_id: finkok_response_id
    )
  end

  def save_pdf_in_amazon(content)
    # Crear folders
    dirname = File.dirname('user_temp/payments/')
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    path = "user_temp/payments/#{self.id}#{Time.now.to_i.to_s[6..10]}.pdf"
    # guardar archivo
    file = File.new(path, 'wb')
    # pdf_from_url
    paper_size = Setting.paper_size_hash(community&.get_setting_value('paper_size'))
    file << WickedPdf.new.pdf_from_string(content, paper_size)

    # Guardar en modelo
    self.receipt = file
    self.save

    file.close

    # limpiar
    File.delete(path)
  end

  def with_interests?
    self.assign_payments.joins(debt: :interests).any?
  end

  def notify_nullified
    title = I18n.t('models.payment.notify_nullified.title', community: community)
    users = property.users.where.not(email: ['', nil])
    users.each do |user|
      content = I18n.t('models.payment.notify_nullified.content',
        community: community,
        user: user,
        amount: to_currency(amount: price, community: community),
        paid_at: I18n.l(paid_at, format: :long_and_day),
        common_expense: "#{I18n.t('views.common_expenses.conjuntion.to_the.one')} #{I18n.t('views.common_expenses.one')}".downcase,
        period_expense: period_expense)

        notify(user, title, content)
    end

    return notify_unknown if self.user.unknown_user

    !users.empty?
  end

  def try_notify_automatic_receipt(wait_time: 2.minutes, tries: 6)
    tries -= 1
    TryNotifyAutomaticPaymentReceiptJob.set(wait: wait_time).perform_later(payment_id: id, num_of_tries: tries)
  end

  def try_notify_receipt(wait_time: 2.minutes, tries: 6, community_id: nil)
    tries -= 1
    emails = property&.users&.with_valid_email&.pluck(:email)&.join(', ')

    TryNotifyPaymentReceiptJob.set(wait: wait_time).perform_later(payment_id: id,
                                                                  num_of_tries: tries,
                                                                  _community_id: community_id,
                                                                  _message: I18n.t('jobs.notify_user_with_pdf.payment', email: emails))
  end

  def try_notify_receipt_to_admin(wait_time: 2.minutes, tries: 6)
    tries -= 1
    TryNotifyPaymentReceiptToAdminJob.set(wait: wait_time).perform_later(payment_id: id,
                                                                         num_of_tries: tries,
                                                                         _message: I18n.t('jobs.notify_user_pdf'))
  end

  def notify_receipt
    if notifying
      errors.add(:notifying, :in_process)

      return false
    end

    title = I18n.t('models.payment.notify_receipt.title', community: community, property_name: property.name)
    body = community.mail_text_payment.to_s.gsub('{monto}', to_currency(amount: price, community: community))
    generate_pdf if property.present? && !generated_pdf

    return false unless receipt.present?

    users = property.users.with_valid_email

    users.each do |user|
      next if user_receive_previous_notifications?(user)

      content = body.gsub('{usuario}', user.first_name.to_s)
      notify(user, title, content)
    end

    notify_unknown if self.user.unknown_user

    if users.empty?
      errors.add(:property, :missing_email_to_notify)
      return false
    end
    # prevent re-generation of pdf when updating receipt_notified , receipt_notified_at and notifying
    self.skip_pdf_generation = true

    update(receipt_notified: true, receipt_notified_at: Time.now, notifying: true)
  end

  def notify_receipt_to_admin
    return false unless confirmed? && receipt.present?

    user = community.administrator
    title = I18n.t('models.payment.notify_receipt.title', community: community, property_name: property.name)
    body = community.mail_text_payment.to_s.gsub('{monto}', to_currency(amount: price, community: community))
    content = body.gsub('{usuario}', user.first_name)

    notify(user, title, content)

    true
  end

  def notify_automatic_payment
    return unless confirmed?

    title = I18n.t('models.payment.notify_receipt.title', community: community, property_name: property.name)
    body = community.mail_text_payment.to_s.gsub('{monto}', to_currency(amount: price, community: community))
    generate_automatic_payment_pdf if property.present? && !generated_pdf
    return false unless receipt.present?

    users = property.users.where.not(email: ['', nil])
    users.each do |user|
      content = body.gsub('{usuario}', user.first_name)
      notify(user, title, content)
    end

    return false if users.empty?

    update(receipt_notified: true, receipt_notified_at: Time.now, notifying: true)
  end

  def notify_automatic_payment_admin
    NotifyAdminAutomaticPaymentJob.perform_later(
      payment_id: id,
      payment_price: to_currency(amount: price, community: community),
      _community_id: community.id,
      user_id: community.administrator.id,
      community_contact_mail: community.contact_email
    )
  end

  def notify_automatic_payment_received
    notify_automatic_payment_admin
    notify_automatic_payment
  end

  def notify(user, title, content)
    if finkok_response&.xml&.present? || (mx_company.present? && community.country_code == 'MX')
      NotifyPaymentWithPdfAndXmlJob.perform_later(
        _community_id:  community.id,
        commission:     purchase_order_payment&.external_commission,
        recipient_id:   user.id,
        recipient_name: user.to_s,
        recipient_type: user.class.name,
        content:        content,
        title:          title,
        origin_id:      self.id,
        origin_type:    self.class.name,
        origin_mail:    community.contact_email.to_s,
        file_name:      receipt.filename,
        payment_id:     id,
        template:       'notify_user_with_pdf',
        email_to:       user.email,
        file_url:       receipt.expiring_url(86_400),
        xml:            finkok_response&.xml,
        _message:       I18n.t('jobs.notify_user_with_pdf.payment', email: user.email)
      )
    else
      NotifyUserWithPdfJob.perform_later(
        _community_id: community.id,
        recipient:     user,
        community:     community,
        content:       content,
        title:         title,
        origin_mail:   community.contact_email.to_s,
        file_name:     receipt.filename,
        object:        self,
        template:      'notify_user_with_pdf_payment',
        email:         user.email,
        commission:    purchase_order_payment&.external_commission,
        _message:      I18n.t('jobs.notify_user_with_pdf.payment', email: user.email),
        extras:        { 'sendgrid_template': 'notify_user_with_pdf_payment' }
      )
    end
  end

  def send_push_notification
    PushNotificationNewPaymentJob.perform_later(payment_id: self.id)
  end

  def notify_unknown
    title = I18n.t(:title, scope: %i[jobs notify_product_receipt_pdf], recipient_name: user.name)
    content = I18n.t(:content, scope: %i[jobs notify_product_receipt_pdf])

    NotifyUserWithPdfJob.perform_later(
      _community_id: community.id,
      recipient:     user,
      community:     community,
      content:       content,
      title:         title,
      origin_mail:   community.contact_email.to_s,
      file_name:     receipt.filename,
      object:        self,
      template:      'notify_user_with_pdf_payment',
      email:         user.email,
      commission:    purchase_order_payment&.external_commission,
      _message:       I18n.t(:message,
                             scope: %i[jobs notify_product_receipt_pdf],
                             user_name: user_name),
      extras:        { 'sendgrid_template': 'notify_user_with_pdf_payment' }
    )
  end

  def self.notify_all(payments)
    payments.each do |p|
      p.notify_receipt if p.confirmed?
    end
  end

  # change all calls to
  def get_payment_type
    return humanize_stp_payment if acts_as_transference?

    Payment.human_enum_name(:payment_type, payment_type)
  end

  def get_payment_type_for_finkok
    return Payment.human_enum_name(:payment_type, 'transference') if spei? || online_payment?

    get_payment_type
  end

  def acts_as_transference?
    purchase_order_payment&.payment_method == Constants::PurchaseOrderPayment::PAYMENT_METHODS[:stp_transfer]
  end

  def humanize_stp_payment
    community.country_code == 'MX' ? I18n.t('activerecord.attributes.payment.payment_types.spei') : I18n.t('activerecord.attributes.payment.payment_types.transference')
  end

  def online?
    ONLINE_PAYMENT_TYPES.include?(payment_type)
  end

  def self.PAYMENTS_TYPES(online: false, community: nil, human: true, spei: false)
    country_code = community&.country_code
    types = COMMON_PAYMENT_TYPES

    local_types = Countries.payment_types(country_code)
    if local_types.present? and country_code.present?
      types += local_types['common'] if local_types['common'].present?
      types += local_types['online'] if local_types['online'].present? and online
      types += local_types['transference'] if local_types['transference'].present?
    end

    # Pending method is only enabled for mexican billing
    types += MX_INVOICE_PAYMENT_TYPES if country_code == 'MX' && community.mx_company.present?
    result = payment_types.select { |pt| types.include?(pt) }
    result = result.keys.collect { |pt| [Payment.human_enum_name(:payment_type, pt), pt] } if human
    result.delete(["SPEI", "spei"]) if !spei
    result.to_h
  end

  def self.ALL_PAYMENTS_TYPES
    payment_types.keys.collect { |pt| [Payment.human_enum_name(:payment_type, pt), pt] }
  end

  #############
  ### EXCEL ###
  #############

  def self.excel_import(params, community, property, user, importer = nil)
    period_expense = if params[:year].present? && params[:month].present?
                       community.get_period_expense params[:month].to_i, params[:year].to_i
                     else
                       community.get_open_period_expense
                     end

    payment_type = case params[:payment][:payment_type].to_s.capitalize.strip
    when 'Redcompra','Red compra' then 'RedCompra' #:red_compra
    when 'Pendiente' then 'Por definir' #:pending
    when 'Pac/pat' then 'PAC/PAT'
    else params[:payment][:payment_type].to_s.capitalize.strip
    end

    params[:payment][:payment_type] = Payment.PAYMENTS_TYPES(community: community)[payment_type]

    params[:payment][:payment_type] = :transference unless params[:payment][:payment_type].present?

    if params.dig(:payment, :price).present?
      params[:payment][:price] = params.dig(:payment, :price).to_d.round(community.get_rounding_decimals)
    end

    payment = community.payments.find(params[:payment][:id]) if params[:payment][:id].present?

    if payment.present?
      payment.update excel_params params
    else
      payment = Payment.new(excel_params(params))
    end

    payment.mark_as_reconciled = community.get_setting_value('automatic_bank_reconciliation').zero?
    payment.period_expense_id = period_expense.id
    payment.property_id = property.id if property.present?
    payment.user_id = user.to_i

    payment.importer_id = importer.id if importer.present?
    payment.importer_type = importer.class.name
    payment.skip_pdf_generation = true
    payment.confirm(period_expense.period, true) unless payment.pending?
    payment.source = ::Constants::Payment::SOURCES[:excel]
    payment.save
    payment
  end

  # SOFT DELETE!
  def self.undo_excel_import(importer, current_user)
    success = true

    result_array = []
    min_folio = 0

    ActiveRecord::Base.transaction do
      to_destroy = importer.payments.includes(:property, :period_expense, :community)

      min_folio = to_destroy.minimum(:folio)

      to_destroy.each do |payment|
        property_name = payment.property&.name || I18n.t('models.property.unassigned')
        if payment.period_expense.common_expense_generated
          result_array << { id: payment.id, property: property_name, period_expense: payment.period_expense.to_s, message: I18n.t('messages.errors.admin.payments.undo_payment_unsuccessful') }
          next
        end

        payment.update(issued: false)
        Payment.where(origin_payment_id: payment.id).update_all(issued: false)

        unless payment.destroy
          success = false
          raise ActiveRecord::Rollback
        end

        result_array << { id: payment.id, property: property_name, period_expense: payment.period_expense.to_s, message: I18n.t('messages.notices.admin.payments.undo_payment_successful') }
      end
    end

    community = importer.community

    if !min_folio.nil? && community.payment_folio.folio >= min_folio
      community.payment_folio.update(folio: min_folio - 1)
    end
    #community.payment_folio.update(folio: Communities::FoliosQueries.max_folio(community))

    NotifyUndoPaymentsExcelJob.perform_later(
      community_id: community.id,
      community_name: community.name,
      result_array: result_array,
      user_id: current_user.id,
      user_name: current_user.to_s,
      origin_id: importer.id
    )
    success
  end

  def self.excel_params(params)
    params.require(:payment).permit(:description, :folio, :generate_invoice_on_create, :paid_at, :payment_number, :payment_type, :price)
  end

  def self.generate_excel(report, community, user, payments, from_date, until_date, force_order: true)
    excel_labels ={
      UNRECOGNIZED: { sheet_name: I18n.t('excels.payments.unrecognized.sheet_name') , title: I18n.t('excels.payments.unrecognized.title')},
      NULLIFIED: { sheet_name: I18n.t('excels.payments.nullified.sheet_name') , title: I18n.t('excels.payments.nullified.title')},
      ALL: { sheet_name: I18n.t('excels.payments.not_nullified.sheet_name') , title: I18n.t('excels.payments.not_nullified.title')},
    }
    payment_sheet = {}
    date_str = ''
    if from_date.present?
      date_str += ". Desde: #{from_date.to_date}"
      until_date ||= Time.now.to_date
      date_str += " Hasta: #{until_date.to_date}"
    end
    payment_sheet[:name] = excel_labels[report][:sheet_name]
    payment_sheet[:title] = ['', excel_labels[report][:title] + date_str ]
    payment_sheet[:sub_title] = ['', community.to_s]
    payment_sheet[:header] = ['',
                              I18n.t('activerecord.models.property.one'),
                              "#{community.sub_community_name}(s)",
                              I18n.t('activerecord.models.property_user.one').to_s,
                              I18n.t('activerecord.attributes.payment.part_owner.identifier').to_s]
    payment_sheet[:header] += [Payment.human_attribute_name(:id)] if user&.admin?
    payment_sheet[:header] += [Payment.human_attribute_name(:folio)]
    payment_sheet[:header] += [Payment.human_attribute_name(:tracking_number)] if community.stp_active?
    payment_sheet[:header] += [Payment.human_attribute_name(:price),
                               Payment.human_attribute_name(:paid_at),
                               Payment.human_attribute_name(:payment_type),
                               Payment.human_attribute_name(:payment_number),
                               Payment.human_attribute_name(:description)]
    payment_sheet[:header] += [Payment.human_attribute_name(:period_expense)] if community.uses_period_control?
    payment_sheet[:header] += [Payment.human_attribute_name(:created_at)]
    payment_sheet[:body] = []
    sheet_format = Hash.new('')
    sheet_format[Payment.human_attribute_name(:price)] = 'price'
    sheet_format[Payment.human_attribute_name(:paid_at)] = 'date'
    sheet_format[Payment.human_attribute_name(:created_at)] = 'date'
    payment_sheet[:style] = payment_sheet[:header].map { |x| sheet_format[x] }

    payment_row = ['']
    payments = payments.order(folio: :desc) if force_order
    payments.each do |payment|
      payment_row += [payment.property.to_s,                            # Propiedad
                      payment.property&.aliquots&.join(', ').to_s,      # sub_community_name
                      payment.property&.person_in_charge,                            # Copropietario
                      payment.property&.user_in_charge&.rut(community_id: community.id).to_s]                  # Rut Copropietario
      payment_row += [payment.id] if user&.admin?                       # ID
      payment_row += [payment.folio]                                    # Folio
      payment_row += [payment.tracking_number] if community.stp_active?
      payment_row += [payment.price,                                    # Monto
                      payment.paid_at&.to_date,                         # Fecha de pago
                      payment.get_payment_type,                         # Medio de pago
                      payment.payment_number,                           # Número de documento
                      payment.description]                              # Comentarios
      payment_row +=  [I18n.l((payment.bill || payment)&.period_expense&.period&.in_time_zone('UTC')&.to_date, format: :month)] if community.uses_period_control? # Período del registro en boleta
      payment_row +=  [payment.created_at.to_date] # Fecha de creación
      payment_sheet[:body].append(
        content: payment_row,
        style:   { alternated: true }
      )
      payment_row = ['']
    end

    # Total
    payment_sheet[:body].append(
      content: ['', 'Total'].concat([''] * (payment_sheet[:header].size - 2)),
      total:   { vertical: true, to_total: payment_sheet[:header].map.each_with_index { |x, i| i if x == 'Monto' }.compact }
    )
    format_to_excel([payment_sheet], community)
  end

  def self.generate_excel_export(community, payments)
    p = Axlsx::Package.new
    wb = p.workbook
    wb.styles do |s|
      time_style = s.add_style format_code: 'yyyy-mm-dd'
      wb.add_worksheet(name: 'Pagos') do |sheet|
        sheet.add_row [ I18n.t('activerecord.models.property.one'), 'Monto', 'Fecha de pago', "Per\xC3\xADodo"]

        styles_array = [nil, nil, time_style, nil]

        payments.order(folio: :desc).each do |payment|
          sheet.add_row [payment.property.to_s,
                         payment.price,
                         payment.paid_at.present? ? payment.paid_at.strftime('%Y-%m-%d') : '',
                         payment.bill&.period_expense&.period&.year.to_i * 100 + payment.bill&.period_expense&.period&.month.to_i], style: styles_array
        end
      end
    end
    p
  end

  def self.get_excel_filename(report, community)
    excel_filename ={
      UNRECOGNIZED: I18n.t('excels.payments.unrecognized.filename', community: community),
      NULLIFIED: I18n.t('excels.payments.nullified.filename', community: community),
      ALL: I18n.t('excels.payments.not_nullified.filename', community: community)
    }
    file_name = excel_filename[report]
    file_name.gsub('/','_')
  end

  def self.get_email_subject_payment_type(report)
    payment_type ={
      UNRECOGNIZED: I18n.t('excels.payments.unrecognized.email_subject'),
      NULLIFIED: I18n.t('excels.payments.nullified.email_subject'),
      ALL: I18n.t('excels.payments.not_nullified.email_subject')
    }
    payment_type[report]
  end

  def self.generate_and_sending_excel_export(
    params, integration_present, payments,
    current_community, current_user, report, from, until_, force_order: true
  )

    if params[:export].present? && integration_present
      ids = params[:payments].present? ? params[:payments].map { |e| e[0] } : nil
      payments = ids.present? ? payments.where(id: ids) : payments
      file_excel = Payment.generate_excel_export(current_community, payments)
    else
      file_excel = Payment.generate_excel(report.to_sym, current_community, current_user, payments, from, until_, force_order: force_order)
    end

    path = get_excel_filename(report.to_sym, current_community)
    file = file_excel.to_stream

    upload_response = S3::UploadGeneratedFile.call(stream: file, path: path)

    return unless upload_response.data[:uploaded]

    NotifyPaymentsExcelJob.perform_later(
      _community_id: current_community.id,
      recipient_id: current_user.id,
      file_url: upload_response.data[:url],
      file_name: path,
      email_subject_payment_type: get_email_subject_payment_type(report.to_sym)
    )
  end

  def self.destroy_unconfirmed_payments(payment_id, payment_class)
    if payment_class == Payment.to_s
      Payment.where(id: payment_id).each { |p| p.destroy unless p.confirmed? }
    else
      BundlePayment.where(id: payment_id).each { |p| p.destroy unless p.confirmed? }
    end
  end

  def business_transaction_description
    bt = BusinessTransaction.where(origin_id: id, origin_type: self.class.name)
    # cuando se anula el pago no pasa por aca el crear la descripcion
    description_part = description.present? ? ", comentarios: #{description}" : ''
    paid_at_part = paid_at.present? ? " - Pagado el: #{paid_at.strftime('%d-%m-%Y')}" : ''
    default_description = "Pago por: #{get_payment_type} , Folio: #{folio}#{description_part}#{paid_at_part}"
    if bt.size > 1 && nullified
      bt_nullified = bt.find_by('description like ?', 'Anular pago%')
      text = "Anular pago #{folio}#{description_part}"
      bt_nullified.update(description: text)
      default_description
    elsif nullified
      "Anular pago #{folio}#{description_part}"
    else
      default_description
    end
  end

  def rfc_hash
    return pending_rfc_hash if pending?
    # 94131500:Organizaciones no gubernamentales
    # SOLO GASTOS COMUNES
    greater_than_zero_assign_payments = assign_payments.select { |assign_payment| assign_payment.price.round(2).positive? }
    products = greater_than_zero_assign_payments.map(&:rfc_hash)
    a_money = available_money + products.sum { |h| h[:Descuento].to_f }

    if a_money.round(3).positive?
      payment_estimator = FuturePaymentsEstimator.new(self, a_money)
      products.push(*payment_estimator.estimated_payments)
    end
    products
  end

  def pending_rfc_hash
    return unless pending?
    [
      PrepareInvoiceHash.create_hash_for_sat(
        description: 'Cuota de mantenimiento',
        id: folio || id,
        amount: price,
        discount: 0
      )
    ]
  end

  def self.irs_status
    ::Constants::Payment::IRS_STATUS.values.reduce(:merge)
  end

  def self.irs_billing_statuses
    ::Constants::Payment::IRS_STATUS[:billing].keys
  end

  def get_irs_status
    Payment.irs_status[self.irs_status]
  end

  def irs_billed_and_pending?
    irs_billed && (payment_type == 'pending')
  end

  def irs_billed_and_not_pending?
    irs_billed && (payment_type != 'pending')
  end

  def irs_status_fail?
    self.irs_status == Payment.irs_status.invert['Fallido']
  end

  def irs_bill(notify = true, general_public = false)
    # Evitar que corran en paralelo muchas veces
    billed_status, success_status, failed_status = Payment.irs_status.invert.values_at(
      'Facturando', 'Exitoso', 'Fallido'
    )
    return if irs_status == billed_status

    receiver_params = if property.present?
                        property.rfc_receiver(general_public: general_public)
                      else
                        Property.new.rfc_receiver(general_public: general_public)
                      end

    update_column(:irs_status, billed_status)
    params = {
      mx_company:      mx_company,
      apply_iva:       false,
      receiver_params: receiver_params,
      folio:           folio,
      serie:           id,
      products:        rfc_hash,
      payment_code:    pending? ? '99' : MxCompany.to_mx_irs(self),
      region:          community.get_region,
      payment_method:  pending? ? 'PPD' : 'PUE',
      payment_params:  { paid_at: paid_at }
    }
    response, _wicked_pdf = Finkok::Document.new(params).facturar
    finkok_response ||= FinkokResponse.new(invoiceable: self)
    finkok_response.update(response)

    if finkok_response.success
      self.irs_status = success_status
      self.irs_billed = true
      self.irs_billed_at = Time.now
      save(validate: false) # especially closed periods
      update_column(:generated_pdf, false)
      generate_pdf(notify: notify, notify_admin: notify)
    else
      self.irs_status = failed_status
      # the PDF is only generated when it has not been generated
      self.skip_pdf_generation = generated_pdf
      save(validate: false) # especially closed periods
      generate_pdf(notify: notify, notify_admin: notify) unless generated_pdf
    end
  rescue StandardError => e
    Rollbar.error(e)
    update_column(:irs_status, failed_status)
  end

  def can_create_complement?
    !pending? && finkok_response.present? && finkok_response.can_create_complement?
  end

  def create_complement(general_public: false)
    payment_params = {
      FechaPago:    paid_at.strftime('%Y-%m-%dT%H:%M:%S'),
      FormaDePagoP: MxCompany.to_mx_irs(self),
      MonedaP:      'MXN',
      Monto:        '%<num>.2f' % { num: price.round(2) }
    }

    params = {
      mx_company:      mx_company,
      receiver_params: property.rfc_receiver(general_public: general_public).merge(UsoCFDI: 'CP01'),
      folio:           folio,
      serie:           id,
      payment_params:  payment_params,
      paper_size:      Setting.paper_size_hash(community.get_setting_value('paper_size'))
    }

    finkok_response.generate_uniq_complement params
  end

  def cancel_irs
    self.finkok_response.cancel mx_company
  end

  def self.filter_payments(from_paid_at: nil, until_paid_at: nil, payment_method: nil, folio: nil, amount: nil, visible: nil, country_code: nil)
    filtered = where(true.to_s)
    filtered = filtered.where('payments.paid_at >= ? ', from_paid_at.to_date) if from_paid_at.present?

    if payment_method.present? && payment_method.to_s != 'all'
      if ONLINE_PAYMENT_TYPES.include? payment_method
        filtered = filtered.where(payment_type: ONLINE_PAYMENT_TYPES)
      elsif country_code == 'MX'
        filtered = filtered.left_joins(:purchase_order_payment)

        if payment_method == 'transference'
          filtered = filtered
            .where(payment_type: payment_method)
            .where('purchase_order_payments.payment_method is null or purchase_order_payments.payment_method != ?', Constants::PurchaseOrderPayment::PAYMENT_METHODS[:stp_transfer])
        elsif payment_method == 'spei'
          filtered = filtered.where('payments.payment_type = ? or (payments.payment_type = ? and purchase_order_payments.id is not null and purchase_order_payments.payment_method = ?)',
            Payment.payment_types[payment_method], Payment.payment_types[:transference], Constants::PurchaseOrderPayment::PAYMENT_METHODS[:stp_transfer])
        else
          filtered = filtered.where(payment_type: payment_method)
        end
      else
        filtered = filtered.where(payment_type: payment_method)
      end
    end

    filtered = filtered.where('payments.paid_at <= ? ', until_paid_at.to_datetime.end_of_day) if until_paid_at.present?
    filtered = filtered.left_joins(:property).where('properties.name ILIKE ? OR payments.folio = ?', "%#{folio}%", folio.to_i) if folio.present?
    filtered = filtered.where(visible: visible) if visible.present?
    filtered = filtered.where(price: amount) if amount.present?
    filtered
  end

  def validate_for_creation(property_id: 0, skip_validation: false, current_community: nil)
    bill = current_community.bills.where(id: self.bill_id).first
    self.price = current_community.round(self.price.to_f)
    self.paid_at = Time.zone.now.strftime('%d/%m/%Y') unless self.paid_at.present?

    if bill.present? || current_community.properties.where(id: property_id).first.present?
      self.property_id = bill.present? ? bill.property_id : property_id

      unless skip_validation
        # If payment without property has the same price, alert about creating possible duplicated payment

        possible_duplicated_payment = current_community.unasigned_payments.where(price: self.price).first
        if possible_duplicated_payment.present?
          properties = current_community.properties
          possible_duplicated_payment.property_id = self.property_id
          return [true, bill]
        end
      end
    elsif (property_id == 0) && skip_validation
      debt_properties = Debt.where(property_id: current_community.properties.pluck(:id)).where('money_balance > 0').select('debts.property_id').group('debts.property_id').having("sum(debts.money_balance) = #{self.price}").pluck(:property_id)

      unless debt_properties.empty?
        properties = current_community.properties
        possible_debt_properties = properties.where(id: debt_properties)

        return [possible_debt_properties.present?, bill]
      end
    end
    [false, bill]
  end

  def self.notify_pending(period_expense, period_control = true, community = nil)
    pending_payments = period_control ? period_expense.notifiable_payments : community.not_notified_payments_without_period_control
    NotifyPaymentsJob
      .perform_later(
        _community_id: community&.id || period_expense.community_id,
        payments_ids: pending_payments.ids,
        _message: I18n.t('views.payments.notify_vouchers')
      ) if pending_payments.count > 0

    pending_payments
  end

  def community_integration_present?
    self.community&.integration&.setting_code('import_bills').present? || false
  end

  def has_pdf
    self.has_receipt?
  end

  def has_pdf_for_business_transaction?
    generated_pdf
  end

  def pdf_url
    self.receipt.expiring_url(FILE_AVAILABILITY_TIME) if self.has_receipt?
  end

  #object action
  def is_assign_action_valid?
    self.visible and !self.nullified and !self.community.properties.empty?
  end

  #object action
  def is_assign_common_expense_action_valid?
    self.visible and !self.nullified
  end

  #object action
  def is_edit_action_valid?
    !self.issued and !self.online?
  end

  #object action
  def is_edit_folio_action_valid?
    !self.issued and !self.online? and self.community.get_setting_value('folio') > 0
  end

  #object action
  def is_hide_action_valid?
    self.nullified
  end

  #object action
  def is_notify_receipt_action_valid?
    confirmed? && receipt.present?
  end

  #object action
  def is_notify_nullified_receipt_action_valid?
    self.nullified
  end

  #object action
  def is_nullify_action_valid?
    !ONLINE_PAYMENT_TYPES.include? self.payment_type and
    !self.issued and self.visible and !self.nullified
  end

  #object action
  def is_set_exported_action_valid?
    self.visible and !self.nullified
  end

  #object action
  def settable_as_exported?
    self.community_integration_present?
  end

  #object action
  def is_show_pdf_action_valid?
    self.generated_pdf
  end

  #object action
  def is_show_cancellation_voucher_action_valid?
    self.property_id.present? and
    !self.generated_pdf and
    self.nullified
  end

  #object action
  def is_show_debt_assignation_action_valid?
    self.assign_payments.present? and
    self.community.get_setting_value('include_debt_assignation_in_payment_pdf').zero?
  end

  #object action
  def is_show_payment_voucher_valid?
    self.property_id.present? and
    !self.generated_pdf and
    !self.nullified
  end

  def process_online_payment_information
    return unless self.online?

    self.property_transaction&.construct_description(true)

    PaymentGateway::PaymentPdf.new(
      PurchaseOrderPayment.find_by(
        payable_type: 'Payment',
        payable_id: self.id
      )
    ).call
  end

  def get_pdf_url
    pdf_url = receipt&.expiring_url(10)
    url?(pdf_url) ? pdf_url : nil
  end

  def can_be_duplicated?
    # no se vericia pagos duplicados para pagos sin asinar.
    return false if self.bill_id.nil?
    Payment.where(price: self.price, bill_id: self.bill_id, period_expense_id: self.period_expense_id, nullified: false).size > 1
  end

  def price_locked?
    return true if bundle_payment_id.present?
    return true if online? || period_expense.common_expense_generated? || receipt_notified
    return false if adjustment? || community_transaction.blank?

    community_transaction_closed?
  end

  def community_transaction_closed?
    community_transaction&.closed? || community_transaction&.bank_transaction_id.present?
  end

  def reconciled?
    community_transaction&.state_id == CommunityTransaction.get_state('paid')
  end

  private

  def automatic_invoice_for_online_payments?
    (community&.get_setting_value('generate_invoice_for_online_payments').to_i == 1) && (spei? || online_payment?)
  end

  def generate_community_transaction?
    !pending? && !debt_relief?
  end

  def generate_invoice
    if automatic_invoice_for_online_payments? && general_public.nil?
      general_public = Properties::GetMissingConfigurations.call(property: property).present?
    end

    PaymentIrsAllJob.perform_later(
      _community_id:      community.id,
      _message:           I18n.t('jobs.payment_irs_all', folios: folio),
      payments_ids:       [id],
      notify:             notify_on_create == 'true',
      general_public_ids: ['true', true].include?(general_public) ? [id] : []
    )
  end

  def match_feliz_depending_state
    return CommunityTransaction.get_state("paid") if community.full_bank_reconciliation_enabled?  && reconciled?

    return CommunityTransaction.get_state("paid") if !community.full_bank_reconciliation_enabled? && (reconciled? || online?)

    CommunityTransaction.get_state("pendding")
  end

  def set_generate_invoice_on_create
    generate_invoice = ['true', true].include?(automatic_invoice_for_online_payments? || generate_invoice_on_create) && !adjustment?
    self.generate_invoice_on_create = generate_invoice
  end

  def paid_at_validation
    unless ::Constants::Payment::PAID_AT_VALID_YEAR_REGEXP.match?(paid_at&.year.to_s) && paid_at&.year.to_s.length == 4
      errors.add(:paid_at, :invalid)
    end
  end

  def user_mail_blacklist_tmp
    [
      'alejandra.venegas@yahoo.com.mx',
      'carrasco.belman.g@outlook.com',
      'cmeza2020@hotmail.com',
      'fvillarrealr@hotmail.com',
      'galdyibarra@gmail.com',
      'guillermo.cordoba@gmail.com',
      'hdbr19@gmail.com',
      'hector.hnzaguilar@gmail.com',
      'joshua.emr@gmail.com',
      'julian.stoelzle@gmail.com',
      'julietafc51@gmail.com',
      'julioatm00@gmail.com',
      'lau12san@hotmail.com',
      'llopezvargas71@gmail.com',
      'martha.pina@mx-integra.com',
      'mayuing@hotmail.com',
      'michellealissonev@gmail.com',
      'ody-123@hotmail.com',
      'pilmont@hotmail.com',
      'portercarlos@me.com',
      'rcnotaria6@hotmail.con',
      'rodrigo.lopez.dominguez@gmail.com',
      'santiagogomezt01@gmail.com',
      'susana@signpro.com.mx',
      'tupatrimonio@hotmail.com',
      'valeri_04@hotmail.com',
      'wahine.api.akua@gmail.com'
    ]
  end

  def user_receive_previous_notifications?(user)
    return false if payment_type != 'spei'

    return true  if user_mail_blacklist_tmp.include?(user.email)

    return user.outgoing_mails.where(origin: self, mail_type: 7, created_at: 6.days.ago..Time.now).present?
  end
end
