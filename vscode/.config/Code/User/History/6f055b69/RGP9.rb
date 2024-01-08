# == Schema Information
#
# Table name: debts
#
#  id                      :integer          not null, primary key
#  common                  :boolean          default(FALSE)
#  custom                  :boolean          default(FALSE)
#  description             :string
#  last_interest_bill_date :datetime
#  money_balance           :decimal(19, 4)   default(0.0)
#  money_paid              :decimal(19, 4)   default(0.0)
#  origin_type             :string
#  paid                    :boolean          default(FALSE)
#  price                   :decimal(19, 4)   default(0.0)
#  priority_date           :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  common_expense_id       :bigint
#  excel_upload_id         :integer
#  origin_id               :integer
#  property_id             :integer
#  reference_id            :integer
#
# Indexes
#
#  index_debts_on_EXTRACT_YEAR_FROM_priority_date  (date_part('year'::text, priority_date))
#  index_debts_on_common_expense_id                (common_expense_id)
#  index_debts_on_origin_id_and_origin_type        (origin_id,origin_type)
#  index_debts_on_priority_date                    (priority_date)
#  index_debts_on_property_id                      (property_id)
#
class Debt < ApplicationRecord
  include ApplicationHelper
  include ObjectActions::ObjectActionHelper
  include Formatter
  extend Algorithms

  attr_accessor :skip_add_payments

  has_paper_trail

  belongs_to :common_expense, optional: true
  belongs_to :origin, polymorphic: true, optional: true
  belongs_to :property, optional: true

  has_one    :interest, inverse_of: :debt

  has_many   :assign_payments
  has_many   :interests, class_name: 'Interest', foreign_key: 'origin_debt_id', inverse_of: :origin_debt
  has_many   :surcharges, -> { where(active: true) }, foreign_key: 'origin_debt_id', dependent: :destroy
  has_many   :deductions, -> { where(active: true) }, foreign_key: 'debt_id', dependent: :destroy

  # Through associations
  has_one    :community, through: :property
  has_one    :period_expense, through: :common_expense

  has_many   :debt_interests, through: :interests, source: :debt
  has_many   :payments, through: :assign_payments, source: :payment
  has_many   :applied_deductions, ->{ applied }, class_name: 'Deduction'

  scope         :active_on, ->(date) { where('priority_date < ? AND money_balance > 0', date) }
  scope         :expired, ->(defaulting_days = 0) { where("debts.priority_date < NOW() - INTERVAL '? days'", defaulting_days) }

  before_save   :update_money_balance
  before_save   :check_priority_date
  after_create  :add_payments
  after_update  :update_price_transaction
  after_update  :update_origin_fined_at
  after_destroy :destroy_assign_payments

  scope :unpaid, -> { where(paid: false) }

  validates :money_paid, numericality: { greater_than_or_equal_to: 0 }
  validates :money_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def balance
    to_currency(amount: money_balance, community: community)
  end

  def priority_date_formatted(format: :default_slash)
    I18n.l(priority_date.to_date, format: format)
  end

  def destroy_assign_payments
    assign_payments.destroy_all
  end

  #####################
  ##   BEFORE SAVE   ##
  #####################
  def get_description(gasto_c = true, detail = true)
    return description if custom

    common_expense = self.common_expense
    interest = self.interest
    message = ''

    if common_expense_id
      message += "#{I18n.t('views.common_expenses.one')}: #{common_expense.period_expense}" if gasto_c
      message += ' - '  if gasto_c && detail
      message += common ? I18n.t('views.debts.common_expenses_description') : I18n.t('views.debts.uncommon_expenses_description') if detail
      message += '- Fondos y Cargos' if !detail && !common

      message
    elsif interest.present?
      interest.origin_name.present? ? "Interés: #{interest.origin_name}" : 'Interés'
    else
      description.to_s
    end
  end

  def update_money_balance
    return true if paid && money_paid == price

    self.money_paid = [self.money_paid, 0].max
    self.money_balance = self.price - self.money_paid
    self.paid = self.money_balance.zero?
    true
  end

  def check_priority_date
    self.priority_date = Time.now if self.priority_date.blank?
    true
  end

  ######################
  ##   AFTER CREATE   ##
  ######################

  def add_payments(except_id: nil)
    return if skip_add_payments

    # Asignar fecha inicial de facturación
    unless last_interest_bill_date.present?
      self.last_interest_bill_date = priority_date
      save
    end

    uncomplete_payments = property.uncomplete_payments.reject { |pa| pa.undid || except_id == pa.id }
    uncomplete_payments.sort_by(&:paid_at).to_a
    uncomplete_payments.each do |pp|
      use = pp.use(money_balance, self)
      pay(use)
      break unless money_balance.positive?
    end

    true
  end

  def check_discounts
    return unless common_expense_id.present?
    last_payment, discount = check_annual_discounts
    last_payment, discount = check_month_discounts if last_payment.blank? || discount.blank?
    return unless discount.present?
    discount_amount = community.round(price * discount.percentage / 100.0)
    return unless discount_amount >= money_balance
    last_payment.generate_discount_adjust(discount_amount, discount.name)
  end

  def check_annual_discounts
    return unless period_expense.present?
    last_payment = payments.where.not(payment_type: 3).where(annual: true)
                           .order(paid_at: :desc).first
    return unless last_payment.present?
    discount = community.discounts
                        .where(active: true, discount_type: 1)
                        .where('period_expenses.period <= ?', period_expense.period)
                        .order(percentage: :desc)
                        .find_by('? <= discounts.expiration_date', last_payment.paid_at)
    [last_payment, discount]
  end

  def check_month_discounts
    last_payment = payments.where.not(payment_type: 3)
                           .where('payments.paid_at < ?', priority_date)
                           .order(paid_at: :desc).first
    return unless last_payment.present?
    discount = period_expense.discounts
                             .where('? OR ?', community.get_setting_value('include_non_common_but_no_interests_for_discounts') == 1, common)
                             .where(active: true, discount_type: 0)
                             .order(percentage: :desc)
                             .find_by('? <= expiration_date', last_payment.paid_at)
    [last_payment, discount]
  end

  #################
  ##   METHODS   ##
  #################

  def update_price_transaction
    return unless saved_change_to_price? || will_save_change_to_price?

    object = nil
    if self.common_expense_id.present?
      # common expenses
      object = self.common_expense
      price = object&.debts&.sum(:price).to_f
      object.update(price: price) if object.present? && object.price != price
    elsif self.interest.present?
      object = self.interest
      object.update(price: self.price)
    elsif origin.present?
      object = origin
      object.update(price: self.price) if object.price != self.price
    end

    if object.present?
      # property transactions
      transaction = object.try(:property_transaction)
      if transaction.present?
        transaction.update(transaction_value: object.price * -1)
        transaction.update_property_future
      end
    end

    reassign_payments([id])
  end

  def update_origin_fined_at
    return unless origin.present? && priority_date.present? && origin.is_a?(PropertyFine)

    origin.update_columns(fined_at: priority_date)
  end

  def interest_pertinency community_interest
    validation = true

    # SI SOLO SE CONSIDERA EGRESOS COMUNES
    if community_interest.only_common_expenses
      #CASO QUE TENGAS INTERESES COMPUESTOS y sea  interés
      validation = false unless (community_interest.compound && !self.common_expense_id.present?) || self.common
    # TODOS LOS EGRESOS sin interés compuesto, y es interés
    elsif !community_interest.compound && !self.common_expense_id.present?
      validation = false
    end

    validation
  end

  # FACTURAR INTERES
  def bill_interest(community_interest, open_period_expense, end_date = Time.now, close = false, apply_fixed_interest = false, cached = false)
    community_interest = community.current_interest unless community_interest.present?
    # Por cada pago, calculamos la deuda hacia adelante. Al final cerramos el inicio del periodo
    # EJ: con deuda de 300 mil y abono 100 mil,
    # #############
    # ##300.000####
    # ##########################
    # ##############200.000#####
    # ############################## ##########
    # ############################## 50,000####
    # ########################################
    #             |             |
    #       Fecha de pago

    # Ver estructura de deuda durante el tiempo

    assign_payments =
      if cached
        self
          .assign_payments
          .select do |ap|
            if last_interest_bill_date.to_date < Constants::CommonExpenses::START_DATE_FOR_INTERESTS_FIX
              ap.paid_at >= last_interest_bill_date.to_date && ap.paid_at < end_date
            else
              ap.paid_at > last_interest_bill_date && ap.paid_at <= end_date
            end
          end
          .sort_by(&:paid_at)
          .reverse!
      else
        self
          .assign_payments
          .where("case
          when ? < '2022/12/05' then paid_at >= ? and paid_at < ?
          else paid_at >= ? and paid_at <= ?
          end", last_interest_bill_date.to_date, last_interest_bill_date.to_date, end_date, last_interest_bill_date.to_date, end_date)
          .order('assign_payments.paid_at desc')
      end
    last_pricing = money_balance
    temp_end = end_date.to_date
    interests = []

    # Aqui registramos la deuda de los 200
    assign_payments.each do |a|
      start_date = a.paid_at.to_date # .end_of_day + 1.minute
      days = (temp_end - start_date).to_i
      interest_price = community_interest.calculate_interest(last_pricing, [days, 0].max).to_f

      # aplicar interes por dia de atraso
      if apply_fixed_interest && community_interest.fixed_daily_interest && last_pricing > community_interest.minimun_debt.to_f
        multiply = days
        fixed_interests = community_interest.price.to_f * community_interest.currency.value.to_f * multiply.to_f
        interest_price += fixed_interests
      else
        fixed_interests = 0
      end

      interest_price = 0 unless property.pays_interests
      interests << { days: (temp_end - start_date).to_i, from: start_date, to: temp_end, base_price: last_pricing, interest_price: interest_price, fixed_interests: fixed_interests }
      temp_end = a.paid_at.to_date
      last_pricing += a.price
    end

    # Aqui registramos la deuda de los 300 mil
    start_date = last_interest_bill_date.to_date
    days = (temp_end - start_date - 1).to_i
    days += 1 if start_date >= Constants::CommonExpenses::START_DATE_FOR_INTERESTS_FIX
    interest_price = community_interest.calculate_interest(last_pricing, [days, 0].max).to_f

    if apply_fixed_interest && (interests.any? { |d| (d[:days].positive? && d[:base_price] > community_interest.minimun_debt.to_f) } || (last_pricing.to_f > community_interest.minimun_debt.to_f && days.positive?))
      # Aplicar interes fijo por primera vez a la propiedad si corresponde
      multiply = community_interest.fixed_daily_interest ? [days, 0].max : 1 # interes por dia o por mes
      fixed_interests = community_interest.price.to_f * community_interest.currency.value.to_f * multiply.to_f
      fixed_interests *= last_pricing / 100.0 if community_interest.price_type == 1
      interest_price += fixed_interests
    else
      fixed_interests = 0
    end

    interest_price = 0 unless property.pays_interests

    if interest_price.to_f > 0.0
      interests << {
        days: days,
        from: start_date,
        to: temp_end,
        base_price: last_pricing,
        interest_price: interest_price.round(community.get_rounding_decimals),
        fixed_interests: fixed_interests
      }
    end

    interests = interests.select { |e| e[:interest_price].to_f.positive? }

    return interests unless close

    ids = []
    interests.each do |i|
      next unless interest_price.to_f > 0.0
      next unless property.pays_interests

      interest = Interest.new
      interest.description = I18n.t(
        'views.interests.description',
        daily_rate: (community_interest.daily_rate * 100).round(4),
        base_price: i[:base_price],
        from: i[:from].strftime('%d-%m-%Y'),
        to: (i[:to] - 1.minute).strftime('%d-%m-%Y')
      )
      interest.description = interest.description + ". Multa: #{fixed_interests}" if apply_fixed_interest
      interest.community_interest_id = community_interest.id
      interest.origin_debt_id        = id
      interest.period_expense_id     = open_period_expense.id
      interest.property_id           = property_id
      interest.price                 = i[:interest_price]
      interest.base_price            = i[:base_price]
      interest.start_date            = i[:from]
      interest.end_date              = i[:to]
      interest.save

      ids << interest
    end

    update(last_interest_bill_date: end_date) if end_date > last_interest_bill_date

    ids
    # # los close-> los que cierran necesitan el id, mientras que el resto el monto
    # return close ? interest : interest_price.to_i
  end

  def pay(price, is_adjustment = false)
    return unless price.positive?

    self.money_paid += price
    self.money_balance -= price
    save
    return unless update_calculation

    # Verificar si le corresponden descuentos
    check_discounts unless is_adjustment  # No checar descuentos para pagos de ajuste
  end

  def update_calculation(not_id = 0)
    self.money_paid = money_paid_with_excluded(id: not_id)
    self.money_balance = price - money_paid
    self.paid = money_paid >= price
    save
  end

  def reassign_payments(selected_debts = [], revert_deductions: true)
    Deduction.bulk_revert(deductions.pluck(:id)) if revert_deductions

    payments_ids, assign_payments_ids =
      assign_payments
        .map { |assign_payment| [assign_payment.payment_id, assign_payment.id] }
        .transpose

    AssignPayment.where(id: assign_payments_ids).delete_all

    update_columns(paid: false, money_balance: price, money_paid: 0)

    payments_query = Payment.includes(:assign_payments, :community_transaction, property: { community: :settings }).order(:paid_at)
    assign_common_expense_with_cached_debts_args = {
      compensation: false,
      debt_ids: selected_debts,
      debts_amount: {},
      cached: true
    }

    # first assigned before
    payments_query.where(id: payments_ids).each do |payment|
      payment.skip_update_transaction = payment.community_transaction&.state_id == CommunityTransaction.get_state('nullified')
      payment.update(completed: false)
      payment.assign_common_expense(**assign_common_expense_with_cached_debts_args)
    end

    completed = []
    uncompleted = []
    # then pending ones
    payments_query.where(
      property_id: property_id,
      state: Payment.reversed_status_hash['Pagado'],
      completed: false,
      nullified: false,
      visible: true
    ).each do |payment|
      payment.assign_common_expense(**assign_common_expense_with_cached_debts_args)
      is_completed = payment.price == payment.assign_payments.pluck(:price).sum
      is_completed == true ? completed << payment.id : uncompleted << payment.id
    end
    Payment.where(id: completed).update_all(completed: true) if completed.present?
    Payment.where(id: uncompleted).update_all(completed: false) if uncompleted.present?
  end

  #############
  ### EXCEL ### SE SUBEN ANTES QUE EL COMMON EXPENSE
  #############

  def self.excel_import(params, property, community, excel_upload)
    # buscar
    if params[:debt][:id].present?
      debt = property.debts.find(params[:debt][:id])
      debt.update(excel_params)
    else
      debt = Debt.new(excel_params(params))
    end

    # período si existe
    if params[:year].present? && params[:month].present?
      period_expense = community.get_period_expense(params[:month].to_i, params[:year].to_i)
      # requerido más abajo
      unless period_expense.expiration_date.present?
        period_expense.set_own_expiration_date
      end
    end

    # Solo ggcc cerrados donde el common expense no cambie.
    if community&.get_open_period_expense&.period <= period_expense.period
      debt.errors.add(:common_expense_id, 'El período tiene que ser anterior al mes abierto.')
      return debt
    end

    # Asignar common expense, tengo dudas si vale la pena.
    common_expense = property.common_expenses.where(period_expense_id: period_expense&.id ).first_or_create(price: debt.price, community_id: property.community_id, description: debt.description, excel_upload_id: excel_upload.id )
    debt.property_id = property.id
    debt.custom = true
    debt.excel_upload_id = excel_upload.id

    debt.save

    # save later to skip update_price_transaction
    debt.update_column :common_expense_id, common_expense.id

    CommonExpenseDetail.create(ref_object_id: debt.id, price: debt.price, title: debt.description, ref_object_class: Debt.to_s, common_expense_id: debt.common_expense_id)

    common_expense.update(price: common_expense&.debts&.sum(:price).to_f) unless common_expense.excel_upload_id == excel_upload.id

    # Crear transacción
    BusinessTransaction.create(transaction_value: debt.price * -1, balance_id: property.balance_id, origin_id: debt.id, origin_type: debt.class.name, description: debt.description, transaction_date: debt.priority_date. present? ? debt.priority_date : Time.now)

    # Crear
    property.balance.update_property_future

    debt
  end

  def self.excel_params params
    params.require(:debt).permit(:description, :price, :priority_date, :common , :last_interest_bill_date)
  end

  # HARD DELETE!
  def self.undo_excel_import(excel_upload)
    success = true

    ActiveRecord::Base.transaction do
      # Busca las propiedades marcadas con el excel_upload y las elimina.
      to_destroy = Debt.where(excel_upload_id: excel_upload.id)
      business_transactions = BusinessTransaction.where(origin_type: Debt.name)
                                                 .joins(%(INNER JOIN "debts" ON "debts"."id" = "business_transactions"."origin_id"))
                                                 .includes(:balance)
                                                 .where(debts: { excel_upload_id: excel_upload.id })
      # requerimos actualizar la cartola resultante
      balances = Balance.where(id: business_transactions.distinct.pluck(:balance_id))

      # common expenses
      common_expenses = CommonExpense.where(excel_upload_id: excel_upload.id)
      common_exp_details = CommonExpenseDetail.joins(:common_expense)
                                              .where(common_expenses: { excel_upload_id: excel_upload.id })

      unless business_transactions.destroy_all && to_destroy.destroy_all&& common_exp_details.destroy_all && common_expenses.destroy_all
        success = false
        raise ActiveRecord::Rollback
      end

      balances.each(&:update_property_future)
    end

    success
  end

  def self.generate_debt_assignation_excel(interest_date, debt_for_interest, debts, property, current_interest, apply_fixed_interest, community)
    document = []
    debt_assignation_sheet = {}
    debt_assignation_sheet[:name] = I18n.t('excels.debts.headers.name')
    debt_assignation_sheet[:title] = ['', I18n.t('excels.debts.headers.title', property: property)]
    debt_assignation_sheet[:sub_title] = ['', community.to_s]
    debt_assignation_sheet[:body] = []
    # Header
    debt_assignation_header = ['' , I18n.t('excels.debts.headers.description'), I18n.t('excels.debts.headers.amount'), I18n.t('excels.debts.headers.paid')]
    debt_assignation_style = ['', '', 'price', 'price']
    debt_assignation_header += [I18n.t('excels.debts.headers.balance'), I18n.t('excels.debts.headers.expiration_date'), I18n.t('excels.debts.headers.months_of_debt')]
    debt_assignation_style += ['price', 'date', '']
    debt_assignation_sheet[:header] = debt_assignation_header
    debt_assignation_sheet[:style] = debt_assignation_style

    # Rows
    debt_assignation_row = ['']
    debt_assignation_row = ['']
    total_monto, total_paid, total_balance = [0,0,0]
    debts.each_with_index do |d, i|
      interest = 0
      debt_assignation_row.push(d.get_description(true, community.get_setting_value("one_debt_only") == 0), d.price, d.money_paid)
      total_monto += d.price
      debt_assignation_row.push(d.money_balance + interest, (d.priority_date - 1.minute).to_date, property.get_debt_time((d.priority_date - 1.minute)))
      total_paid += d.money_paid
      total_balance += d.money_balance + interest
      debt_assignation_sheet[:body].append(
        content: debt_assignation_row,
        style: { alternated: true }
      )
      debt_assignation_row = ['']
    end
    # Total
    debt_assignation_sheet[:body].append({
      content: ['', I18n.t('excels.debts.total')] + ['']*(debt_assignation_style.size - 2),
      total: { vertical: true }
    })
    document.push(debt_assignation_sheet)
    format_to_excel(document, community)
  end

  def self.generate_excel(excel_name:, params:)
    case excel_name
    when 'community_debts_excel'
      Debts::CommunityDebtsExcelService.call(**params)
    end
  end

  def self.generate_debt_assignation_pdf(property:)
    hash = property.generate_debts_pdf_hash

    ApplicationController.render(
      template: 'debts/debt_assignation',
      layout: 'pdf',
      formats: [:pdf],
      assigns: hash
    )
  end

  ##obtener periodo asociado
  def period_debt
    period = origin&.period_expense&.period if origin.present?
    period = interest&.period_expense&.period if interest.present?
    period = period_expense&.period if period_expense.present?
    period
  end

  def self.community_common_debt_count_by_property(community, properties_ids = [], data_limit = false)
    response = Debts::CommunityMorosity.call(community: community, properties_ids: properties_ids, sort: :for_panel, data_limit: data_limit)

    { properties_info: response.data[:properties_info], threshold_exceeded: response.data[:threshold_exceeded] }
  end

  def self.user_common_debt_count_by_property(user)
    Debt.joins(property: :property_users).joins(
      'LEFT JOIN interests ON interests.debt_id = debts.id'
    ).where(
      'debts.paid = false AND debts.money_balance > 0 AND interests.id IS NULL AND debts.priority_date < ?', Time.now
    ).where(property_users: { user_id: user.to_i }).select(
      'properties.id property_id, COUNT(DISTINCT debts.common_expense_id) morosity_months'
    ).group('properties.id').index_by(&:property_id)
  end

  def delayed_months
    return nil if self&.period_expense&.expiration_date.nil?

    (Time.now.year - self.period_expense&.expiration_date&.year) * 12 +
    (Time.now.month - self.period_expense&.expiration_date&.month)
  end

  def debt_time
    self.property.get_debt_time((self.priority_date - 1.minute))
  end

  def pending
    self.price > self.money_paid ? (self.price - self.money_paid) : 0
  end

  #object action
  def is_destroy_action_valid?
    self.common_expense.nil? || self.common_expense.initial_setup
  end

  def set_to_zero_or_destroy
    if self.price.zero?
      self.destroy_property_fine
      self.destroy!
    else
      self.update!(price: 0)
    end
  end

  def destroy_property_fine
    return unless origin.is_a?(PropertyFine)

    origin.destroy
  end

  def expiration_date
    priority_date + community.defaulting_days.days
  end

  private

  def money_paid_with_excluded(id: 0)
    if association(:assign_payments).loaded?
      loaded_assign_payments_price_sum_with_excluded(id: id)
    else
      queried_assign_payments_price_sum_with_excluded(id: id)
    end
  end

  def loaded_assign_payments_price_sum_with_excluded(id: 0)
    assign_payments.reject { |assign_payment| assign_payment.id == id }.sum(&:price)
  end

  def queried_assign_payments_price_sum_with_excluded(id: 0)
    assign_payments.where.not(id: id).sum(:price)
  end
end
