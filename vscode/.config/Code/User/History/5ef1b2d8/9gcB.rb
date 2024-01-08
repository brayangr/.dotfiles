# == Schema Information
#
# Table name: common_expenses
#
#  id                      :bigint           not null, primary key
#  description             :text
#  expiration_date         :date
#  fixed_common_expense    :decimal(19, 4)   default(0.0)
#  importer_id             :integer
#  importer_type           :string
#  initial_setup           :boolean          default(FALSE)
#  name                    :string
#  non_common_price        :decimal(19, 4)   default(0.0)
#  notified_at             :datetime
#  price                   :decimal(19, 4)   default(0.0)
#  to_delete               :boolean          default(FALSE)
#  transaction_confirmed   :boolean          default(FALSE)
#  verified                :boolean          default(FALSE)
#  created_at              :datetime
#  updated_at              :datetime
#  bill_id                 :integer
#  community_id            :integer
#  community_interest_id   :integer
#  debt_id                 :integer
#  excel_upload_id         :integer
#  period_expense_id       :integer
#  property_id             :integer
#  property_transaction_id :integer
#  reference_id            :integer
#
# Indexes
#
#  index_common_expenses_on_community_id                   (community_id)
#  index_common_expenses_on_importer_type_and_importer_id  (importer_type,importer_id)
#  index_common_expenses_on_period_expense_id              (period_expense_id)
#  index_common_expenses_on_property_id                    (property_id)
#  index_common_expenses_on_property_transaction_id        (property_transaction_id)
#
require 'period_closing/bills_callback'
require 'period_closing/update_common_expense_property_transactions'
require 'period_closing/update_common_expense_bill'
require 'period_closing/creator_debts_and_transactions'
require 'period_closing/period_bills_creator'

class CommonExpense < ApplicationRecord
  include Importable
  include Formatter
  include CommonExpenseLikeExcel
  include HasPeriodExpensesScopes

  has_paper_trail limit: 1, on: %i[destroy]

  belongs_to :bill, optional: true
  has_many   :common_expense_details, dependent: :destroy
  belongs_to :community, optional: true
  has_one    :community_interest
  has_many   :debts, dependent: :destroy
  belongs_to :period_expense, optional: true
  belongs_to :property, inverse_of: :common_expenses, optional: true
  belongs_to :property_transaction, class_name: 'BusinessTransaction', foreign_key: :property_transaction_id, dependent: :destroy, optional: true

  # Through associations
  has_many   :assign_payments, through: :debts
  has_many   :debt_interests, through: :debts
  has_many   :interests, through: :debts, dependent: :destroy, source: :interests
  has_many   :marks, through: :property

  # Dependant through associations
  has_many   :payments, through: :assign_payments
  scope :property_history, lambda {
    includes(:period_expense, :bill)
      .where(verified: true).order('period_expenses.period DESC')
  }

  # Dependency on the order of possible values in common_expense_fixed setting
  FIXED_TYPES = {
    0 => :service_billings,
    1 => :fixed_amount,
    2 => :square_meter,
    3 => :total_amount_to_pay
  }.freeze

  ####################
  ##   ATTRIBUTES   ##
  ####################

  def to_s
    name
  end

  def extensive_title
    self.name + ' - ' + (self.property ? self.property.person_in_charge.to_s : '')
  end

  def unpaid_past_common_expenses
    self.property.common_expenses.joins(:period_expense, :debts).where('debts.paid = ? AND period_expenses.period < ?', false, self.period_expense.period).order('period_expenses.period ASC')
  end

  def property_fines_debts
    period_expense_table = PeriodExpense.arel_table
    property_fines = property.property_fines.joins(
      :period_expense
    ).preload(:debt).where(
      period_expense_table[:period].lt(period_expense.period)
    )
    property_fines.map(&:debt).compact.reject(&:paid)
  end

  def self.unpaid_past_common_expenses period_expense

  end

  def money_balance
    self.debts.sum(:money_balance)
  end

  def money_paid
    self.debts.sum(:money_paid)
  end

  # def period
  #   self.period_expense
  # end

  ################################
  ##   ATTRIBUTES GASTO COMUM   ##
  ################################


  def get_bill
    self.bill.present? ? self.bill.bill : nil
  end

  # [TO DELETE] SOLO LO NO PAGADO
  def self.unpaid_common_expenses properties
    CommonExpense.joins(:debts).where('common_expenses.property_id in (?) and debts.paid = ?', properties, false).sum('debts.money_balance')
  end

  def self.fixed_type(key:)
    I18n.t("models.common_expense.fixed_types.#{FIXED_TYPES[key]}")
  end

  ################
  ##   STATUS   ##
  ################


  # TODELETE
  def percentage_paid
    (self.debt.money_paid / self.price)
  end

  def self.unpaid_proportion period_expense_ids
    CommonExpense.joins(:debts).select('common_expenses.period_expense_id, (sum(debts.money_balance::DOUBLE PRECISION) / sum(debts.price::DOUBLE PRECISION)) as unpaid_proportion').where('common_expenses.period_expense_id in (?)', period_expense_ids ).group("common_expenses.period_expense_id").map { |e| [e.period_expense_id, e.unpaid_proportion] }.to_h
  end

  def self.paid_proportion period_expense_ids
    CommonExpense.joins(:debts).select('common_expenses.period_expense_id, (sum(debts.money_paid::DOUBLE PRECISION) / sum(debts.price::DOUBLE PRECISION)) as paid_proportion').where('common_expenses.period_expense_id in (?)', period_expense_ids).group('common_expenses.period_expense_id').map { |e| [e.period_expense_id, e.paid_proportion] }.to_h
  end

  #######################
  ##   BUILD PAYMENT   ##
  #######################

  def add_details(common_expense_details)

    details = []
    # price = 0
    common_expense_details.each do |common_expense_detail|
      pd = CommonExpenseDetail.new(common_expense_detail)
      pd.common_expense_id = self.id
      pd.period_expense_id = self.period_expense_id
      # price += pd.price
      details << pd
    end
    # CommonExpenseDetail.import details, :validate => false

    # self.price = price
    # self.save
    return details
  end

  def self.verify_all(period_expense:, user:, new_bt_date: nil)
    Log.create(
      admin: user.admin?,
      value: I18n.t('logs.close_common_expense.verify_all'),
      user_id: user.id,
      community_id: period_expense.community_id,
      origin_class: 'CE_Performance',
      origin_id: period_expense.id
    )

    period_expense.common_expenses.update_all(expiration_date: period_expense.expiration_date, verified: true)
    community = period_expense.community
    common_expenses          = period_expense.common_expenses.includes(:common_expense_details, :property, :assign_payments)
    common_expense_fixed     = community.get_setting_value('common_expense_fixed')

    debts_transactions_generator = PeriodClosing::CreatorDebtsAndTransactions.new(common_expenses, community, user, new_bt_date)
    debts_transactions_generator.call

    Log.create(
      admin: user.admin?,
      value: I18n.t('logs.close_common_expense.transactions_and_debts'),
      user_id: user.id,
      community_id: period_expense.community_id,
      origin_class: 'CE_Performance',
      origin_id: period_expense.id
    )

    bill_creator = PeriodClosing::PeriodBillsCreator.new(
      period_expense,
      period_expense.common_expenses.preload(:common_expense_details, assign_payments: :payment),
      common_expense_fixed
    )
    bill_creator.generate


    Log.create(
      admin: user.admin?,
      value: I18n.t('logs.close_common_expense.bills_and_bill_details_saved'),
      user_id: user.id,
      community_id: period_expense.community_id,
      origin_class: 'CE_Performance',
      origin_id: period_expense.id
    )

    # Update Common Expenses y transactions ids
    PeriodClosing::UpdateCommonExpensePropertyTransactions.call(period_expense.id)
    PeriodClosing::UpdateCommonExpenseBill.call(period_expense.id)

    Log.create(
      admin: user.admin?,
      value: I18n.t('logs.close_common_expense.completed'),
      user_id: user.id,
      community_id: period_expense.community_id,
      origin_class: 'CE_Performance',
      origin_id: period_expense.id
    )
  end


  def verify save = true, pe_undid_future_payment = nil, common_expense_fixed = nil, one_debt_only = nil, period_expense = nil
    self.verified = true

    # CREATE TRANSACTION PARA EL BALANCE DE LA PROPIEDAD
    transaction = self.create_business_transaction save

    # CREAR DEUDA
    debt = self.create_debt save, one_debt_only

    bill, bill_details = self.create_bill save, pe_undid_future_payment, common_expense_fixed, period_expense

    self.save if save

    return transaction, debt, bill, bill_details
  end

  def create_business_transaction(save = true, new_bt_date = nil)
    pt = self.property_transaction
    unless pt.present?
      description = self.initial_setup ? 'Saldo inicial' : self.name
      transaction_date = new_bt_date.present? ? new_bt_date : Time.now
      pt = BusinessTransaction.new(transaction_value: self.price * -1, balance_id: self.property.balance_id, origin_id: self.id, origin_type: self.class.name, description: description, transaction_date: transaction_date)
      if save
        pt.save
        self.property_transaction_id = pt.id if pt.id.present?
        self.save
      end
    end
    return pt
  end

  def create_bill(save = true, pe_undid_future_payment = nil, common_expense_fixed = nil, period_expense = nil)
    if bill.present?
      self.save
      new_bill = bill
    else
      new_bill = Bill.new(
        property_id: property_id, active_common_expense_id: id, period_expense_id: period_expense_id,
        fixed_common_expense: fixed_common_expense, expiration_date: expiration_date
      )
    end

    # Subtract payments made the next month, when the common expense was undone
    if pe_undid_future_payment.nil?
      period_expense = PeriodExpense.find(period_expense_id) if period_expense.nil?
      pe_undid_future_payment = period_expense.undid ? period_expense.get_next.first.payments.where(property_id: property_id).sum(:price) : 0
    end

    if save
      new_bill.save
      self.bill_id = new_bill.id
      self.save
      new_bill.generate(price, property_fines_debts, unpaid_past_common_expenses, pe_undid_future_payment)

      new_bill
    else
      bill_details = new_bill.pre_generate(self, property_fines_debts, common_expense_fixed, unpaid_past_common_expenses, pe_undid_future_payment, period_expense)

      [new_bill, bill_details]
    end
  end

  def generate_associated_bill(current_date = Time.now, save = true, cached = false)
    if self.bill.present?
      new_bill = self.bill
    else
      new_bill = Bill.new(dummy: true, fixed_common_expense: self.fixed_common_expense)
      new_bill.property = self.property
      new_bill.active_common_expense = self
      new_bill.period_expense = self.period_expense
      new_bill.expiration_date = self.expiration_date
    end
    new_bill.save
    property = self.property
    new_bill.generate(self.price, property_fines_debts, property.unpaid_common_expenses, 0, save)
    # Los interes y los abonos hay que calcularlos aparte
    interest_debt = property.get_total_interest(current_date, cached)
    if interest_debt.present? && interest_debt != 0
      #Se suma el monto anterior contando sus abonos correspondientes
      if self.community.get_setting_value('decompose_interests_in_bill').zero?
        # Cero es sí para esta configuración
        current_debt = property.get_expired_debt(current_date, cached)
        current_interest_detail = BillDetail.new(title: 'Intereses y multas', price: current_debt, ref_object_id: 0, ref_object_class: 'Interest', bill_id: self.id, description: "Intereses generados en mes de #{period_expense}")
        previous_interests_details = BillDetail.new(title: 'Intereses y multas', price: (interest_debt-current_debt), ref_object_id: 0, ref_object_class: 'Interest', bill_id: self.id, description: "Intereses acumulados hasta #{I18n.l((period_expense.period - 1.month).to_date, format: :month)}")
        new_bill.bill_details << current_interest_detail
        new_bill.bill_details << previous_interests_details
      else
        #Se suma el monto anterior contando sus abonos correspondientes
        new_bill.bill_details << BillDetail.create(bill_id: new_bill.id, title: 'Intereses y multas', price: interest_debt.to_f, ref_object_id: 0, ref_object_class: 'Interest')
      end
      new_bill.price += interest_debt
    end
    # EN new bill solo se considera los intereses ya ejecutados
    # new_bill.price += property.get_expired_debt
    future_assign_payment = [new_bill.price, property.available_money].min

    # Abonos
    if future_assign_payment.to_i > 0
      new_bill.bill_details << BillDetail.create(bill_id: new_bill.id, title: 'Abono', price: future_assign_payment.to_f * -1, ref_object_id: 0, ref_object_class: 'AssignPayment')
      # EL ABONO SE REGISTRA EN LA BOLETA new_bill.price -= future_assign_payment
    end
    new_bill.bar_code = '123456789'
    new_bill.save if save
    new_bill.reload
  end

  def generate_sample_pdf(min_pages = false, current_date = Time.now, only_hash = false, async_funds: false)
    new_bill = generate_associated_bill(current_date)

    # retorna el string directo cuando es dummy
    bill = Bill.preload_for_pdf_generation.find_by(id: new_bill.id)
    gen_info = BillsCommon::GenerationInfo.new(false, only_hash)
    com_info = BillsCommon::CommunityInfo.new(new_bill.community)
    period_info = BillsCommon::PeriodInfo.new(
      new_bill.community, new_bill.period_expense, min_pages, async_funds: async_funds)
    bill_pdf = bill.generate_pdf(gen_info, com_info, period_info)

    if bill.present? # Lo destruimos inmediatamente
      bill.bill_details.delete_all
      bill.destroy
    end

    DestroyDummysJob.perform_later(_community_id: property.community_id, period_expense_id: self.period_expense_id, _message: "#{I18n.t('jobs.instanced.destroy_dummys')} #{property.community_id}")
    bill_pdf
  end

  def create_debt save = true, one_debt_only = nil

    if self.initial_setup
      common_expenses_debt_price = (self.price.to_f - self.non_common_price.to_f)
    elsif self.community.get_setting_value('common_expense_fixed') > 0
      common_expenses_debt_price = self.fixed_common_expense + self.common_expense_details.where(ref_object_class: %w[Income Mark]).sum(:price).round(community.get_rounding_decimals)
    else
      common_expenses_debt_price = self.common_expense_details.where(ref_object_class: %w[ServiceBilling Mark Income]).select("SUM(CASE WHEN ref_object_class = 'Mark' THEN ROUND(price::numeric, #{community.get_rounding_decimals}) ELSE 0 END) + ROUND(SUM(CASE WHEN ref_object_class = 'ServiceBilling' THEN price ELSE 0 END)::numeric, #{community.get_rounding_decimals}) + ROUND(SUM(CASE WHEN ref_object_class = 'Income' THEN price ELSE 0 END)::numeric, #{community.get_rounding_decimals}) AS price").map(&:price).sum.round(community.get_rounding_decimals)
    end

    # Otras deudas
    if self.initial_setup
      self.non_common_price = self.non_common_price.to_f
    elsif self.community.get_setting_value('common_expense_fixed') > 0
      # otros cobros no incluidos
      self.non_common_price = self.common_expense_details.where(ref_object_class: %w[Community PropertyFine ProvisionPeriodExpense]).sum(:price).round(community.get_rounding_decimals)
    else
      self.non_common_price = (self.price.to_f - common_expenses_debt_price)
    end
    self.save if save

    debts = []
    # no debería llegar nulo
    one_debt_only = self.community.get_setting_value('one_debt_only') if (one_debt_only.nil? and self.community.present? )
    if one_debt_only.to_i == 0
      # Deuda común
      debts << Debt.new(common: true, price: common_expenses_debt_price, priority_date: self.expiration_date - 1.day + 2.second, property_id: self.property_id, common_expense_id: self.id)
      # Deuda sin interés
      debts << Debt.new(price: self.non_common_price, priority_date: self.expiration_date - 1.day + 1.second, property_id: self.property_id, common_expense_id: self.id)
    else
      # Deuda común Simple
      debts << Debt.new(common: true, price: common_expenses_debt_price + self.non_common_price, priority_date: self.expiration_date - 1.day + 2.second, property_id: self.property_id, common_expense_id: self.id)
    end

    if save
      debts.each do |b|
        b.save
      end
    end
    return debts

    # return true
  end



  # DEPRECADO: AHORA SOLO SE CONFIRMA A TRAVÉS DE UN PARTIAL PAYMENT
  def confirm save = true
    self.state = reversed_status_hash['Pagado']
    # self.money_paid = self.price
    self.save if save
    # TODO mandar mail que el pago fue aceptado
  end

  def reject
    if Time.now.to_date > expiration_date
      self.state = reversed_status_hash['Atrasado']
    else
      self.state = reversed_status_hash['Pago Rechazado']
    end
    self.save
    # TODO mandar mail que el pago fue rechazado
  end

  # Para creación normal de los usuarios
  # TODO: merge de este método con self.first_setup
  def self.set_initial_setup_for_property params, property, excel_upload = nil
    period_expense = property.community.last_closed_period_expense
    common_expense = property.common_expenses.where(period_expense_id: period_expense.id).first_or_create

    # actualizar
    common_expense.update excel_params params
    common_expense.name = 'Saldo inicial CF'
    common_expense.price = 0 if common_expense.price.blank? || common_expense.price < 0
    common_expense.expiration_date = period_expense.expiration_date
    common_expense.initial_setup = true
    common_expense.importer = excel_upload

    # CREAR DEUDA
    common_expense.save
    common_expense.verify

    # Ver si hay deudas generadas por sistema que tengan common expenses
    debts = Debt.where(common_expense_id: nil).where(priority_date: period_expense.expiration_date, property_id: property.id)
    debts.update_all(common_expense_id: common_expense.id) unless debts.empty?

    # TODO: debería ir en first_setup? O sólo aquí?
    new_bill = common_expense.create_bill
    new_bill.update(initial_setup: true)

    # Asociar lecturas iniciales (open y closed) para los medidores existentes
    property.setup_meters
  end

  #############
  ### EXCEL ###
  #############

  def self.excel_import(params, community, property, excel_upload = nil)
    if params[:year].present? && params[:month].present?
      period_expense = community.get_period_expense(params[:month].to_i, params[:year].to_i)
    else
      # sino, el último gasto común emitido
      period_expense = community.last_closed_period_expense
    end

    return first_setup(params, community, property, period_expense, excel_upload)
  end

  # Exclusivo Excel Super Admin
  def self.first_setup params, community, property, period_expense, excel_upload = nil
    # buscar
    common_expense = community.common_expenses.find(params[:common_expense][:id]) if params[:common_expense][:id].present?
    common_expense = community.common_expenses.where(property_id: property.id, period_expense_id: period_expense.id).first_or_create if common_expense.blank?

    # redondear montos iniciales
    if params[:common_expense][:non_common_price].present?
      params[:common_expense][:non_common_price] = params[:common_expense][:non_common_price].to_d.round(community.get_rounding_decimals)
    end
    if params[:common_expense][:price].present?
      params[:common_expense][:price] = params[:common_expense][:price].to_d.round(community.get_rounding_decimals)
    end

    # actualizar
    common_expense.update excel_params params
    common_expense.name = 'Saldo inicial CF'
    common_expense.price = 0 if (common_expense.price.blank? || common_expense.price < 0)
    common_expense.errors.add(:price, 'Valor no puede ser menor que 0.') if common_expense.price < 0
    common_expense.expiration_date = period_expense.expiration_date
    common_expense.initial_setup = true
    common_expense.importer = excel_upload

    if params[:common_expense][:months_less]
      common_expense.expiration_date = common_expense.expiration_date - params[:common_expense][:months_less].to_i.month
    end

    # mark as verified, just for reference
    common_expense.verified = true

    common_expense.save

    # Ver si hay deudas generadas por sistema que tengan common expenses
    debts = Debt.where(common_expense_id: nil).where(priority_date: period_expense.expiration_date, property_id: property.id)
    debts.update_all(common_expense_id: common_expense.id) unless debts.empty?

    new_bill = common_expense.create_bill
    common_expense.create_business_transaction true # crear transaction
    common_expense.create_debt # crear debts
    new_bill.unconfirm(false)
    new_bill.property.balance.reload
    new_bill.update(initial_setup: true)
    return common_expense
  end


  ###############
  ### Queries ###
  ###############

  def self.get_common_expense_data(period_expense, properties, get_fines = false)
    billed_fines = CommonExpense.billed_fines_data(period_expense, properties)
    close_interest_date = period_expense.close_interest_date
    property_ids = properties.map(&:id)
    payments = Property.unassigned_payments property_ids
    common_expense_debt = Property.get_common_expense_debt property_ids, payments
    total_interest = Property.get_total_interest(properties, close_interest_date, period_expense.id)
    fines = nil
    if get_fines
      fines = CommonExpenseDetail.joins(:common_expense).where(
        common_expenses:  { period_expense_id: period_expense.id },
        ref_object_class: PropertyFine.to_s
      ).distinct.pluck(:title)
    end
    [common_expense_debt, total_interest, fines, billed_fines]
  end

  def self.billed_fines_data(period_expense, properties)
    properties.each_with_object({}) do |property, hash|
      hash[property.id] = property.unpaid_debts.select do |debt|
        debt.origin_type == 'PropertyFine' &&
          debt.money_balance.positive?
      end.sum(&:money_balance)
    end
  end

  # HARD DELETE!
  def self.undo_excel_import(excel_upload)
    success = true
    ActiveRecord::Base.transaction do
      payments = Payment.where(importer: excel_upload)
      common_expenses = CommonExpense.where(importer: excel_upload)
      period_expense = common_expenses.first.period_expense
      bills = Bill.joins(:common_expenses).where(common_expenses: { importer: excel_upload })
      debts = Debt.joins(:common_expense).where(common_expenses: { importer: excel_upload })
      business_transactions = BusinessTransaction.joins(%(INNER JOIN "common_expenses" ON "common_expenses"."id" = "business_transactions"."origin_id"))
                                                 .where(origin_type: CommonExpense.name, common_expenses: { importer: excel_upload })
      # set money_balance to its original value (zero)
      Balance.joins(:business_transactions, %(INNER JOIN "common_expenses" ON "common_expenses"."id" = "business_transactions"."origin_id"))
             .where(business_transactions: { origin_type: CommonExpense.name }, common_expenses: { importer: excel_upload })
             .update_all(money_balance: 0)
      unless debts.delete_all && business_transactions.delete_all && payments.delete_all && bills.delete_all && common_expenses.delete_all
        success = false
        raise ActiveRecord::Rollback
      end
      # set PeriodExpenses initial values
      period_expense.update(
        common_expense_generated: false,
        common_expense_generated_at: nil,
        initial_setup: false,
        bill_generated: false,
        bill_generated_at: nil,
        paid: false,
        blocked: false,
        global_amount: nil
      )
    end
    success
  end

  def self.excel_params params
    params.require(:common_expense).permit(:price, :non_common_price)
  end

  def self.get_locale(locale_acron)
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

  ######################
  ### EXCEL GENERATE ###
  ######################

  def self.generate_grouped_open_period_excel(period_expense, users, properties, community)
    # Data
    # F18n
    common_expense_debt, total_interest, fines = CommonExpense.get_common_expense_data period_expense, properties, false
    document = []
    common_expenses_sheet = {}
    common_expenses_sheet[:name] = period_expense.to_s
    common_expenses_sheet[:title] = ['', "#{I18n.t('views.common_expenses.other')} #{period_expense}"]
    common_expenses_sheet[:sub_title] = ['', community.to_s]
    common_expenses_sheet[:body] = []

    # Header
    common_expenses_header, common_expenses_style = generate_common_expenses_excel_header(
      community: community,
      fines: fines,
      grouped: true,
      period_expense: period_expense
    )
    common_expenses_sheet[:header] = common_expenses_header
    common_expenses_sheet[:style]  = common_expenses_style

    # Rows
    rows_to_operate = []
    users.each do |user|
      user[1].each do |property_user|
        property_user.each do |group_name, array|
          common_expenses_sheet[:body].append(
            content: ['', "#{user[0]} - #{group_name}"].concat([''] * (common_expenses_header.size - 2)),
            style: { style_array: [''] + (common_expenses_header.drop(1)).map { |x| 'sub_header' } }
          )
          array.each do |property_array|
            property = property_array[1]
            common_expenses_row = add_open_row(
              property: property,
              community: community,
              period_expense: period_expense,
              common_expense_debt: common_expense_debt,
              total_interest: total_interest,
              fines: fines,
              grouped: true
            )
            common_expenses_sheet[:body].append(
              content: common_expenses_row,
              style: { alternated: true }
            )
          end
          rows_to_operate << (common_expenses_sheet[:body].size)
          # Subtotal
          common_expenses_sheet[:body].append(
            content: ['', 'Total'] + [''] * (common_expenses_style.size - 2),
            style: { style_array: common_expenses_style.map { |x| x == 'price' ? 'white_price_bold' : 'white_bold' } },
            total: { vertical: true, to_total: (2..common_expenses_style.size - 1).to_a, range: array.size }
          )
        end
      end
    end

    # Total
    common_expenses_sheet[:body].append(
      content: ['', 'Total'] + [''] * (common_expenses_style.size - 2),
      total: { vertical: true, to_total: (2..common_expenses_style.size - 1).to_a, to_operate: rows_to_operate }
    )
    document.push(common_expenses_sheet)
    format_to_excel(document, community)
  end

  def self.generate_excel_summary(sums, community, enabled_provisions)
    #F18n
    document = []
    summary_sheet = {}
    summary_sheet[:name] = 'Resumen'
    summary_sheet[:title] = ['', "Resumen de #{I18n.t('views.common_expenses.other')}"]
    summary_sheet[:sub_title] = ['', community.to_s]
    summary_sheet[:body] = []

    # Header
    summary_header = ['', 'Mes']
    summary_style = ['', '']
    sums.each do |p|
      summary_header << I18n.l(p[0].to_date, format: :month)
      summary_style << 'price'
    end
    summary_sheet[:header] = summary_header
    summary_sheet[:style]  = summary_style
    summary_sheet[:column_widths] = { specific: { 'Mes' => 20 } }

    # Rows
    summary_body = []
    summary_body << ['', "#{I18n.t('excels.common_expenses.proration')} #{I18n.t('views.common_expenses.one').downcase}"]
    summary_body << ['', I18n.t('activerecord.models.remuneration')]
    summary_body << ['', I18n.t('excels.common_expenses.income')]
    summary_body << ['', I18n.t('excels.common_expenses.reserve_fund')]
    summary_body << ['', I18n.t('excels.common_expenses.individual_proration')]
    summary_body << ['', I18n.t('views.common_expenses.provisions')] if enabled_provisions
    summary_body << ['', I18n.t('activerecord.models.property_fine')]
    summary_body << ['', I18n.t('excels.common_expenses.month_total')]
    summary_body << ['', I18n.t('excels.common_expenses.overdue_capital')]
    summary_body << ['', I18n.t('excels.common_expenses.interests_and_fines')]
    summary_body << ['', I18n.t('excels.common_expenses.payment')]

    month_total_index = 6
    sums.each do |p|
      prorrateo = community.get_setting_value('common_expense_fixed') == 0 ? p[1]['ServiceBilling'].to_f : p[1]['common_expense_fixed'].to_f
      summary_body_index = -1
      summary_body[summary_body_index+=1] << prorrateo # Prorrateo gasto común
      summary_body[summary_body_index+=1] << p[1]['SalaryPayment'].to_f # Remuneraciones
      summary_body[summary_body_index+=1] << p[1]['Income'].to_f # Ingresos
      summary_body[summary_body_index+=1] << p[1]['Community'].to_f # Fondo de reserva
      summary_body[summary_body_index+=1] << p[1]['Mark'].to_f # Prorrateo consumo individual
      if enabled_provisions
        summary_body[summary_body_index+=1] << p[1]['ProvisionPeriodExpense'].to_f # Provisiones
        month_total_index = 7
      end
      summary_body[summary_body_index+=1] << p[1]['PropertyFine'].to_f # Cargos
      summary_body[summary_body_index+=1] << '' # Total del mes
      summary_body[summary_body_index+=1] << p[1]['Bill'].to_f # Capital Atrasado antes del mes
      summary_body[summary_body_index+=1] << p[1]['Interest'].to_f # Intereses antes de emitir
      summary_body[summary_body_index+=1] << p[1]['AssignPayment'].to_f.abs * -1 # Abonos antes de emitir
    end

    summary_body.each do |sb|
      summary_sheet[:body].append(
        content: sb,
        style: { alternated: true }
      )
    end

    # Total del mes
    summary_sheet[:body][month_total_index][:total] = { vertical: true, to_operate: [*0..(month_total_index-1)] }
    summary_sheet[:body][month_total_index][:style] = { style_array: summary_style.map { |x| x == '' ? 'sub_header' : 'sub_header_' + x } }

    # Total
    summary_sheet[:body].append(
      content: ['', 'Total'] + [''] * (summary_style.size - 2),
      total: { vertical: true, to_operate: [*month_total_index..(summary_body.length-1)] }
    )
    document.push(summary_sheet)
    format_to_excel(document, community)
  end

  def self.generate_debt_excel(bill) # Informe de deudas

    #F18n
    property = bill.property
    community = property.community
    file_contents = StringIO.new
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: property.to_s

    #formating row 1
    setting_provisions = property.community.get_setting_value('enabled_provisions') == 1
    enabled_provisions = setting_provisions || community.provisions.any?
    summary_body_index = enabled_provisions ? 10 : 9
    header_format = Spreadsheet::Format.new size: summary_body_index, pattern: 1, color: :white, pattern_fg_color: :green, align: :left, vertical_align: :center
    bold_format   = Spreadsheet::Format.new weight: :bold
    summary_body_index.times.each { |x| sheet.row(3).set_format(x + 1, header_format) && sheet.column(x + 1).width = 20}
    sheet.row(3).height = 20

    title_format = Spreadsheet::Format.new size: 30 #, weight: :bold
    sheet.row(1).set_format(1, title_format)
    sheet.row(1).insert(1, "Informe de #{I18n.t('views.property.debt.one')}")
    sheet.column(0).width = 3

    headers_titles = []
    headers_titles << I18n.t('excels.common_expenses.month')
    headers_titles << I18n.t('views.common_expenses.one')
    headers_titles << "#{I18n.t('excels.common_expenses.reserve')} #{community.reserve_fund.percentage}%"
    headers_titles << I18n.t('views.common_expenses.consumption')
    headers_titles << I18n.t('views.common_expenses.provisions') if enabled_provisions
    headers_titles << I18n.t('activerecord.models.property_fine')
    headers_titles << I18n.t('activerecord.models.community_interest')
    headers_titles << I18n.t('views.commons.total')
    headers_titles << I18n.t('views.common_expenses.paid')
    headers_titles << I18n.t('views.common_expenses.balance')

    sheet.row(3).insert(1, *headers_titles)

    property.common_expenses.where(verified: true, initial_setup: false).joins(:period_expense).order('period_expenses.period DESC').each_with_index do |common_expense, index|

      if community.get_setting_value('common_expense_fixed') == 1 # gasto común fijo
        gc = community.common_price
      elsif community.get_setting_value('common_expense_fixed') == 2 # gasto común fijo TOTAL PRORRATEADO
        gc = (proration * community.common_price).round(community.get_rounding_decimals)
      else # GASTO COMUN
        gc = common_expense.common_expense_details.select { |x| %w[ServiceBilling Income].include?(x.ref_object_class) }.collect(&:price).insert(0,0).inject(:+).round(community.get_rounding_decimals)
      end

      reserve_fund = common_expense.common_expense_details.select { |x| x.ref_object_class == 'Community' }.sum(&:price)
      marks_consumed = common_expense.common_expense_details.select { |x| x.ref_object_class ==  'Mark' }.sum(&:price).round(community.get_rounding_decimals)

      fines = common_expense.common_expense_details.select { |x| x.ref_object_class == 'PropertyFine' }.sum(&:price)

      interests = common_expense.debts.map { |e| e.debt_interests.map(&:price).sum }.sum
      paid = common_expense.debts.map { |e| e.money_paid + e.debt_interests.map(&:money_paid).sum }.sum
      balance = common_expense.debts.map { |e| e.money_balance + e.debt_interests.map(&:money_balance).sum }.sum

      total_propiedad = gc + reserve_fund + marks_consumed + fines
      if enabled_provisions
        provisions = common_expense.common_expense_details.select { |x| x.ref_object_class == 'ProvisionPeriodExpense' }.sum(&:price)
        total_propiedad += provisions
      end

      final_info = []
      final_info << common_expense.period_expense.to_s
      final_info << gc
      final_info << reserve_fund
      final_info << marks_consumed
      final_info << provisions if enabled_provisions
      final_info << fines
      final_info << interests
      final_info << total_propiedad
      final_info << paid
      final_info << balance
      sheet.row(index + 4).insert(1 , *final_info)
      sheet.row(index + 4).set_format(final_info.length, bold_format)
    end

    book.write file_contents

    file_contents
  end

  def self.delay_destroy common_expenses_ids
    CommonExpense.where(id: common_expenses_ids).destroy_all
  end

  def has_pdf_for_business_transaction?
    bill&.bill&.present? || false
  end

  def self.generate_excel(excel_name:, params:)
    service_params = params.is_a?(Hash) ? params : JSON.parse(params)
    case excel_name
    when 'open_period_excel'
      CommonExpenses::OpenPeriodExcelService.call(**service_params)
    end
  end
end
